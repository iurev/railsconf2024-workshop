# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::TagManager do
  include RoutingHelper

  subject { described_class.instance }

  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:status) { Fabricate(:status, account: account) }

  describe '#url_for' do
    it 'returns a string' do
      expect(subject.url_for(account)).to be_a String
    end
  end

  describe '#uri_for' do
    it 'returns a string' do
      expect(subject.uri_for(account)).to be_a String
    end
  end

  describe '#to' do
    it 'returns public collection for public status' do
      status.update!(visibility: :public)
      expect(subject.to(status)).to eq ['https://www.w3.org/ns/activitystreams#Public']
    end

    it 'returns followers collection for unlisted status' do
      status.update!(visibility: :unlisted)
      expect(subject.to(status)).to eq [account_followers_url(status.account)]
    end

    it 'returns followers collection for private status' do
      status.update!(visibility: :private)
      expect(subject.to(status)).to eq [account_followers_url(status.account)]
    end

    it 'returns URIs of mentions for direct status' do
      status.update!(visibility: :direct)
      mentioned = Fabricate(:account)
      status.mentions.create(account: mentioned)
      expect(subject.to(status)).to eq [subject.uri_for(mentioned)]
    end

    it "returns URIs of mentioned group's followers for direct statuses to groups" do
      status.update!(visibility: :direct)
      mentioned = Fabricate(:account, domain: 'remote.org', uri: 'https://remote.org/group', followers_url: 'https://remote.org/group/followers', actor_type: 'Group')
      status.mentions.create(account: mentioned)
      expect(subject.to(status)).to include(subject.uri_for(mentioned))
      expect(subject.to(status)).to include(subject.followers_uri_for(mentioned))
    end

    context 'with followers and requested followers' do
      let_it_be(:bob) { Fabricate(:account, username: 'bob') }
      let_it_be(:alice) { Fabricate(:account, username: 'alice') }
      let_it_be(:foo) { Fabricate(:account) }
      let_it_be(:author) { Fabricate(:account, username: 'author', silenced: true) }
      let_it_be(:direct_status) { Fabricate(:status, visibility: :direct, account: author) }

      before_all do
        bob.follow!(author)
        FollowRequest.create!(account: foo, target_account: author)
        direct_status.mentions.create(account: alice)
        direct_status.mentions.create(account: bob)
        direct_status.mentions.create(account: foo)
      end

      it "returns URIs of mentions for direct silenced author's status only if they are followers or requesting to be" do
        expect(subject.to(direct_status))
          .to include(subject.uri_for(bob))
          .and include(subject.uri_for(foo))
          .and not_include(subject.uri_for(alice))
      end
    end
  end

  describe '#cc' do
    it 'returns followers collection for public status' do
      status.update!(visibility: :public)
      expect(subject.cc(status)).to eq [account_followers_url(status.account)]
    end

    it 'returns public collection for unlisted status' do
      status.update!(visibility: :unlisted)
      expect(subject.cc(status)).to eq ['https://www.w3.org/ns/activitystreams#Public']
    end

    it 'returns empty array for private status' do
      status.update!(visibility: :private)
      expect(subject.cc(status)).to eq []
    end

    it 'returns empty array for direct status' do
      status.update!(visibility: :direct)
      expect(subject.cc(status)).to eq []
    end

    it 'returns URIs of mentions for non-direct status' do
      mentioned = Fabricate(:account)
      status.mentions.create(account: mentioned)
      expect(subject.cc(status)).to include(subject.uri_for(mentioned))
    end

    context 'with followers and requested followers' do
      let_it_be(:bob) { Fabricate(:account, username: 'bob') }
      let_it_be(:alice) { Fabricate(:account, username: 'alice') }
      let_it_be(:foo) { Fabricate(:account) }
      let_it_be(:author) { Fabricate(:account, username: 'author', silenced: true) }
      let_it_be(:public_status) { Fabricate(:status, visibility: :public, account: author) }

      before_all do
        bob.follow!(author)
        FollowRequest.create!(account: foo, target_account: author)
        public_status.mentions.create(account: alice)
        public_status.mentions.create(account: bob)
        public_status.mentions.create(account: foo)
      end

      it "returns URIs of mentions for silenced author's non-direct status only if they are followers or requesting to be" do
        expect(subject.cc(public_status))
          .to include(subject.uri_for(bob))
          .and include(subject.uri_for(foo))
          .and not_include(subject.uri_for(alice))
      end
    end

    it 'returns poster of reblogged post, if reblog' do
      bob = Fabricate(:account, username: 'bob', domain: 'example.com', inbox_url: 'http://example.com/bob')
      alice = Fabricate(:account, username: 'alice')
      original_status = Fabricate(:status, visibility: :public, account: bob)
      reblog = Fabricate(:status, visibility: :public, account: alice, reblog: original_status)
      expect(subject.cc(reblog)).to include(subject.uri_for(bob))
    end
  end

  describe '#local_uri?' do
    it 'returns false for non-local URI' do
      expect(subject.local_uri?('http://example.com/123')).to be false
    end

    it 'returns true for local URIs' do
      expect(subject.local_uri?(subject.uri_for(account))).to be true
    end
  end

  describe '#uri_to_local_id' do
    it 'returns the local ID' do
      expect(subject.uri_to_local_id(subject.uri_for(account), :username)).to eq account.username
    end
  end

  describe '#uri_to_resource' do
    it 'returns the local account' do
      expect(subject.uri_to_resource(subject.uri_for(account), Account)).to eq account
    end

    it 'returns the remote account by matching URI without fragment part' do
      remote_account = Fabricate(:account, uri: 'https://example.com/123', domain: 'example.com')
      expect(subject.uri_to_resource('https://example.com/123#456', Account)).to eq remote_account
    end

    it 'returns the local status for ActivityPub URI' do
      expect(subject.uri_to_resource(subject.uri_for(status), Status)).to eq status
    end

    it 'returns the local status for OStatus tag: URI' do
      expect(subject.uri_to_resource(OStatus::TagManager.instance.uri_for(status), Status)).to eq status
    end

    it 'returns the remote status by matching URI without fragment part' do
      remote_status = Fabricate(:status, uri: 'https://example.com/123')
      expect(subject.uri_to_resource('https://example.com/123#456', Status)).to eq remote_status
    end
  end
end