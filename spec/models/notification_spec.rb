# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification, :aggregate_failures do
  describe '#target_status' do
    let_it_be(:status) { Fabricate(:status) }
    let_it_be(:reblog) { Fabricate(:status, reblog: status) }
    let_it_be(:favourite) { Fabricate(:favourite, status: status) }
    let_it_be(:mention) { Fabricate(:mention, status: status) }

    it 'returns correct target_status for different activities' do
      expect(Fabricate(:notification, activity: reblog).target_status).to eq status
      expect(Fabricate(:notification, activity: favourite).target_status).to eq status
      expect(Fabricate(:notification, activity: mention).target_status).to eq status
    end
  end

  describe '#type' do
    it 'returns correct type for different activities' do
      expect(described_class.new(activity: Status.new).type).to eq :reblog
      expect(described_class.new(activity: Mention.new).type).to eq :mention
      expect(described_class.new(activity: Favourite.new).type).to eq :favourite
      expect(described_class.new(activity: Follow.new).type).to eq :follow
    end
  end

  describe 'Setting account from activity_type' do
    it 'sets the notification from_account correctly for different activity types' do
      status = Fabricate(:status)
      expect(Fabricate.build(:notification, activity_type: 'Status', activity: status).from_account).to eq(status.account)

      follow = Fabricate(:follow)
      expect(Fabricate.build(:notification, activity_type: 'Follow', activity: follow).from_account).to eq(follow.account)

      favourite = Fabricate(:favourite)
      expect(Fabricate.build(:notification, activity_type: 'Favourite', activity: favourite).from_account).to eq(favourite.account)

      follow_request = Fabricate(:follow_request)
      expect(Fabricate.build(:notification, activity_type: 'FollowRequest', activity: follow_request).from_account).to eq(follow_request.account)

      poll = Fabricate(:poll)
      expect(Fabricate.build(:notification, activity_type: 'Poll', activity: poll).from_account).to eq(poll.account)

      report = Fabricate(:report)
      expect(Fabricate.build(:notification, activity_type: 'Report', activity: report).from_account).to eq(report.account)

      mention = Fabricate(:mention)
      expect(Fabricate.build(:notification, activity_type: 'Mention', activity: mention).from_account).to eq(mention.status.account)

      account = Fabricate(:account)
      expect(Fabricate.build(:notification, activity_type: 'Account', account: account).account).to eq(account)
    end
  end

  describe '.preload_cache_collection_target_statuses' do
    let_it_be(:mention) { Fabricate(:mention) }
    let_it_be(:status) { Fabricate(:status) }
    let_it_be(:reblog) { Fabricate(:status, reblog: Fabricate(:status)) }
    let_it_be(:follow) { Fabricate(:follow) }
    let_it_be(:follow_request) { Fabricate(:follow_request) }
    let_it_be(:favourite) { Fabricate(:favourite) }
    let_it_be(:poll) { Fabricate(:poll) }

    let_it_be(:notifications) do
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

    subject do
      described_class.preload_cache_collection_target_statuses(notifications) do |target_statuses|
        Status.preload(:account).where(id: target_statuses.map(&:id))
      end
    end

    it 'returns [] when notifications are empty' do
      expect(described_class.preload_cache_collection_target_statuses([])).to eq []
    end

    it 'preloads and replaces target statuses correctly' do
      result = subject

      expect(result[0].type).to eq :mention
      expect(result[0].association(:mention)).to be_loaded
      expect(result[0].mention.association(:status)).to be_loaded
      expect(result[0].target_status.association(:account)).to be_loaded
      expect(result[0].target_status).to eq mention.status

      expect(result[1].type).to eq :status
      expect(result[1].association(:status)).to be_loaded
      expect(result[1].target_status.association(:account)).to be_loaded
      expect(result[1].target_status).to eq status

      expect(result[2].type).to eq :reblog
      expect(result[2].association(:status)).to be_loaded
      expect(result[2].status.association(:reblog)).to be_loaded
      expect(result[2].target_status.association(:account)).to be_loaded
      expect(result[2].target_status).to eq reblog.reblog

      expect(result[3].type).to eq :follow
      expect(result[3].target_status).to be_nil

      expect(result[4].type).to eq :follow_request
      expect(result[4].target_status).to be_nil

      expect(result[5].type).to eq :favourite
      expect(result[5].association(:favourite)).to be_loaded
      expect(result[5].favourite.association(:status)).to be_loaded
      expect(result[5].target_status.association(:account)).to be_loaded
      expect(result[5].target_status).to eq favourite.status

      expect(result[6].type).to eq :poll
      expect(result[6].association(:poll)).to be_loaded
      expect(result[6].poll.association(:status)).to be_loaded
      expect(result[6].target_status.association(:account)).to be_loaded
      expect(result[6].target_status).to eq poll.status
    end
  end
end