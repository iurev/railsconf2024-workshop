# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification do
  describe '#target_status' do
    let_it_be(:status) { Fabricate(:status) }
    let_it_be(:reblog) { Fabricate(:status, reblog: status) }
    let_it_be(:favourite) { Fabricate(:favourite, status: status) }
    let_it_be(:mention) { Fabricate(:mention, status: status) }

    let(:notification) { Fabricate(:notification, activity: activity) }

    context 'when Activity is reblog' do
      let(:activity) { reblog }

      it 'returns status' do
        expect(notification.target_status).to eq status
      end
    end

    context 'when Activity is favourite' do
      let(:activity) { favourite }

      it 'returns status' do
        expect(notification.target_status).to eq status
      end
    end

    context 'when Activity is mention' do
      let(:activity) { mention }

      it 'returns status' do
        expect(notification.target_status).to eq status
      end
    end
  end

  describe '#type' do
    it 'returns :reblog for a Status' do
      notification = described_class.new(activity: Status.new)
      expect(notification.type).to eq :reblog
    end

    it 'returns :mention for a Mention' do
      notification = described_class.new(activity: Mention.new)
      expect(notification.type).to eq :mention
    end

    it 'returns :favourite for a Favourite' do
      notification = described_class.new(activity: Favourite.new)
      expect(notification.type).to eq :favourite
    end

    it 'returns :follow for a Follow' do
      notification = described_class.new(activity: Follow.new)
      expect(notification.type).to eq :follow
    end
  end

  describe 'Setting account from activity_type' do
    context 'when activity_type is a Status' do
      let_it_be(:status) { Fabricate(:status) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Status', activity: status)
        expect(notification.from_account).to eq(status.account)
      end
    end

    context 'when activity_type is a Follow' do
      let_it_be(:follow) { Fabricate(:follow) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Follow', activity: follow)
        expect(notification.from_account).to eq(follow.account)
      end
    end

    context 'when activity_type is a Favourite' do
      let_it_be(:favourite) { Fabricate(:favourite) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Favourite', activity: favourite)
        expect(notification.from_account).to eq(favourite.account)
      end
    end

    context 'when activity_type is a FollowRequest' do
      let_it_be(:follow_request) { Fabricate(:follow_request) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'FollowRequest', activity: follow_request)
        expect(notification.from_account).to eq(follow_request.account)
      end
    end

    context 'when activity_type is a Poll' do
      let_it_be(:poll) { Fabricate(:poll) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Poll', activity: poll)
        expect(notification.from_account).to eq(poll.account)
      end
    end

    context 'when activity_type is a Report' do
      let_it_be(:report) { Fabricate(:report) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Report', activity: report)
        expect(notification.from_account).to eq(report.account)
      end
    end

    context 'when activity_type is a Mention' do
      let_it_be(:mention) { Fabricate(:mention) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Mention', activity: mention)
        expect(notification.from_account).to eq(mention.status.account)
      end
    end

    context 'when activity_type is an Account' do
      let_it_be(:account) { Fabricate(:account) }

      it 'sets the notification from_account correctly' do
        notification = Fabricate.build(:notification, activity_type: 'Account', account: account)
        expect(notification.account).to eq(account)
      end
    end
  end

  describe '.preload_cache_collection_target_statuses' do
    subject do
      described_class.preload_cache_collection_target_statuses(notifications) do |target_statuses|
        Status.preload(:account).where(id: target_statuses.map(&:id))
      end
    end

    context 'when notifications are empty' do
      let(:notifications) { [] }

      it 'returns []' do
        expect(subject).to eq []
      end
    end

    context 'when notifications are present' do
      let_it_be(:mention) { Fabricate(:mention) }
      let_it_be(:status) { Fabricate(:status) }
      let_it_be(:reblog) { Fabricate(:status, reblog: Fabricate(:status)) }
      let_it_be(:follow) { Fabricate(:follow) }
      let_it_be(:follow_request) { Fabricate(:follow_request) }
      let_it_be(:favourite) { Fabricate(:favourite) }
      let_it_be(:poll) { Fabricate(:poll) }

      let(:notifications) do
        [
          Fabricate(:notification, type: :mention, activity: mention),
          Fabricate(:notification, type: :status, activity: status),
          Fabricate(:notification, type: :reblog, activity: reblog),
          Fabricate(:notification, type: :follow, activity: follow),
          Fabricate(:notification, type: :follow_request, activity: follow_request),
          Fabricate(:notification, type: :favourite, activity: favourite),
          Fabricate(:notification, type: :poll, activity: poll),
        ]
      end

      before_all do
        notifications.each(&:reload)
      end

      context 'with a preloaded target status' do
        it 'preloads mention' do
          expect(subject[0].type).to eq :mention
          expect(subject[0].association(:mention)).to be_loaded
          expect(subject[0].mention.association(:status)).to be_loaded
        end

        it 'preloads status' do
          expect(subject[1].type).to eq :status
          expect(subject[1].association(:status)).to be_loaded
        end

        it 'preloads reblog' do
          expect(subject[2].type).to eq :reblog
          expect(subject[2].association(:status)).to be_loaded
          expect(subject[2].status.association(:reblog)).to be_loaded
        end

        it 'preloads follow as nil' do
          expect(subject[3].type).to eq :follow
          expect(subject[3].target_status).to be_nil
        end

        it 'preloads follow_request as nill' do
          expect(subject[4].type).to eq :follow_request
          expect(subject[4].target_status).to be_nil
        end

        it 'preloads favourite' do
          expect(subject[5].type).to eq :favourite
          expect(subject[5].association(:favourite)).to be_loaded
          expect(subject[5].favourite.association(:status)).to be_loaded
        end

        it 'preloads poll' do
          expect(subject[6].type).to eq :poll
          expect(subject[6].association(:poll)).to be_loaded
          expect(subject[6].poll.association(:status)).to be_loaded
        end
      end

      context 'with a cached status' do
        it 'replaces mention' do
          expect(subject[0].type).to eq :mention
          expect(subject[0].target_status.association(:account)).to be_loaded
          expect(subject[0].target_status).to eq mention.status
        end

        it 'replaces status' do
          expect(subject[1].type).to eq :status
          expect(subject[1].target_status.association(:account)).to be_loaded
          expect(subject[1].target_status).to eq status
        end

        it 'replaces reblog' do
          expect(subject[2].type).to eq :reblog
          expect(subject[2].target_status.association(:account)).to be_loaded
          expect(subject[2].target_status).to eq reblog.reblog
        end

        it 'replaces follow' do
          expect(subject[3].type).to eq :follow
          expect(subject[3].target_status).to be_nil
        end

        it 'replaces follow_request' do
          expect(subject[4].type).to eq :follow_request
          expect(subject[4].target_status).to be_nil
        end

        it 'replaces favourite' do
          expect(subject[5].type).to eq :favourite
          expect(subject[5].target_status.association(:account)).to be_loaded
          expect(subject[5].target_status).to eq favourite.status
        end

        it 'replaces poll' do
          expect(subject[6].type).to eq :poll
          expect(subject[6].target_status.association(:account)).to be_loaded
          expect(subject[6].target_status).to eq poll.status
        end
      end
    end
  end
end