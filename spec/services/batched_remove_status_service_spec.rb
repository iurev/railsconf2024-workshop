# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchedRemoveStatusService, sidekiq: :inline do
  subject { described_class.new }

  let_it_be(:alice) { Fabricate(:account) }
  let_it_be(:bob)   { Fabricate(:account, username: 'bob', domain: 'example.com') }
  let_it_be(:jeff)  { Fabricate(:account) }
  let_it_be(:hank)  { Fabricate(:account, username: 'hank', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox') }

  let!(:status_alice_hello) { PostStatusService.new.call(alice, text: "Hello @#{bob.pretty_acct}") }
  let!(:status_alice_other) { PostStatusService.new.call(alice, text: 'Another status') }

  before_all do
    jeff.user.update(current_sign_in_at: Time.zone.now)
    jeff.follow!(alice)
    hank.follow!(alice)
  end

  before do
    stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
    allow(Redis.any_instance).to receive(:publish).and_return(0)
  end

  it 'removes statuses' do
    subject.call([status_alice_hello, status_alice_other])
    expect { Status.find(status_alice_hello.id) }.to raise_error ActiveRecord::RecordNotFound
    expect { Status.find(status_alice_other.id) }.to raise_error ActiveRecord::RecordNotFound
  end

  it 'removes statuses from author\'s home feed' do
    subject.call([status_alice_hello, status_alice_other])
    expect(HomeFeed.new(alice).get(10).pluck(:id)).to_not include(status_alice_hello.id, status_alice_other.id)
  end

  it 'removes statuses from local follower\'s home feed' do
    subject.call([status_alice_hello, status_alice_other])
    expect(HomeFeed.new(jeff).get(10).pluck(:id)).to_not include(status_alice_hello.id, status_alice_other.id)
  end

  it 'notifies streaming API of followers' do
    expect(Redis.any_instance).to receive(:publish).with("timeline:#{jeff.id}", any_args).at_least(:once)
    subject.call([status_alice_hello, status_alice_other])
  end

  it 'notifies streaming API of public timeline' do
    expect(Redis.any_instance).to receive(:publish).with('timeline:public', any_args).at_least(:once)
    subject.call([status_alice_hello, status_alice_other])
  end

  it 'sends delete activity to followers' do
    subject.call([status_alice_hello, status_alice_other])
    expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.at_least_once
  end
end