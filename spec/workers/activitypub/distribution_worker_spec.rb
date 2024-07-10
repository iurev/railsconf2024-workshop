# frozen_string_literal: true

require 'rails_helper'

describe ActivityPub::DistributionWorker do
  subject { described_class.new }

  let_it_be(:status)   { Fabricate(:status) }
  let_it_be(:follower) { Fabricate(:account, protocol: :activitypub, inbox_url: 'http://example.com', domain: 'example.com') }

  before_all do
    follower.follow!(status.account)
  end

  describe '#perform' do
    context 'with public status' do
      before do
        status.update(visibility: :public)
      end

      it 'delivers to followers' do
        expect_push_bulk_to_match(ActivityPub::DeliveryWorker, [[kind_of(String), status.account.id, 'http://example.com', anything]]) do
          subject.perform(status.id)
        end
      end
    end

    context 'with private status' do
      before do
        status.update(visibility: :private)
      end

      it 'delivers to followers' do
        expect_push_bulk_to_match(ActivityPub::DeliveryWorker, [[kind_of(String), status.account.id, 'http://example.com', anything]]) do
          subject.perform(status.id)
        end
      end
    end

    context 'with direct status' do
      let_it_be(:mentioned_account) { Fabricate(:account, protocol: :activitypub, inbox_url: 'https://foo.bar/inbox', domain: 'foo.bar') }

      before do
        status.update(visibility: :direct)
        status.mentions.create!(account: mentioned_account)
      end

      it 'delivers to mentioned accounts' do
        expect_push_bulk_to_match(ActivityPub::DeliveryWorker, [[kind_of(String), status.account.id, 'https://foo.bar/inbox', anything]]) do
          subject.perform(status.id)
        end
      end
    end
  end
end