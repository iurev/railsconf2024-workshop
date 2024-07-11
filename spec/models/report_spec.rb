# frozen_string_literal: true

require 'rails_helper'

describe Report do
  let_it_be(:target_account) { Fabricate(:account) }
  let_it_be(:status) { Fabricate(:status) }

  describe 'statuses' do
    it 'returns the statuses for the report' do
      _other = Fabricate(:status)
      report = Fabricate(:report, status_ids: [status.id])

      expect(report.statuses).to eq [status]
    end
  end

  describe 'media_attachments_count' do
    it 'returns count of media attachments in statuses' do
      status1 = Fabricate(:status, ordered_media_attachment_ids: [1, 2])
      status2 = Fabricate(:status, ordered_media_attachment_ids: [5])
      report  = Fabricate(:report, status_ids: [status1.id, status2.id])

      expect(report.media_attachments_count).to eq 3
    end
  end

  describe 'assign_to_self!' do
    let_it_be(:original_account) { Fabricate(:account) }
    let_it_be(:current_account) { Fabricate(:account) }
    let(:report) { Fabricate(:report, assigned_account_id: original_account.id) }

    before do
      report.assign_to_self!(current_account)
    end

    it 'assigns to a given account' do
      expect(report.assigned_account_id).to eq current_account.id
    end
  end

  describe 'unassign!' do
    let(:report) { Fabricate(:report, assigned_account_id: Fabricate(:account).id) }

    before do
      report.unassign!
    end

    it 'unassigns' do
      expect(report.assigned_account_id).to be_nil
    end
  end

  describe 'resolve!' do
    let_it_be(:acting_account) { Fabricate(:account) }
    let(:report) { Fabricate(:report, action_taken_at: nil, action_taken_by_account_id: nil) }

    before do
      report.resolve!(acting_account)
    end

    it 'records action taken' do
      expect(report.action_taken?).to be true
      expect(report.action_taken_by_account_id).to eq acting_account.id
    end
  end

  describe 'unresolve!' do
    let_it_be(:acting_account) { Fabricate(:account) }
    let(:report) { Fabricate(:report, action_taken_at: Time.now.utc, action_taken_by_account_id: acting_account.id) }

    before do
      report.unresolve!
    end

    it 'unresolves' do
      expect(report.action_taken?).to be false
      expect(report.action_taken_by_account_id).to be_nil
    end
  end

  describe 'unresolved?' do
    it 'returns true when action is not taken' do
      report = Fabricate(:report, action_taken_at: nil)
      expect(report.unresolved?).to be true
    end

    it 'returns false when action is taken' do
      report = Fabricate(:report, action_taken_at: Time.now.utc)
      expect(report.unresolved?).to be false
    end
  end

  describe 'history' do
    let(:report) { Fabricate(:report, target_account_id: target_account.id, status_ids: [status.id], created_at: 3.days.ago, updated_at: 1.day.ago) }

    before do
      Fabricate(:action_log, target_type: 'Report', account_id: target_account.id, target_id: report.id, created_at: 2.days.ago)
      Fabricate(:action_log, target_type: 'Account', account_id: target_account.id, target_id: report.target_account_id, created_at: 2.days.ago)
      Fabricate(:action_log, target_type: 'Status', account_id: target_account.id, target_id: status.id, created_at: 2.days.ago)
    end

    it 'returns right logs' do
      expect(report.history.count).to eq 3
    end
  end

  describe 'validations' do
    let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com', protocol: :activitypub, inbox_url: 'http://example.com/inbox') }

    it 'is invalid if comment is longer than 1000 characters only if reporter is local' do
      report = Fabricate.build(:report, comment: Faker::Lorem.characters(number: 1001))
      expect(report.valid?).to be false
      expect(report).to model_have_error_on_field(:comment)
    end

    it 'is valid if comment is longer than 1000 characters and reporter is not local' do
      report = Fabricate.build(:report, account: remote_account, comment: Faker::Lorem.characters(number: 1001))
      expect(report.valid?).to be true
    end

    it 'is invalid if it references invalid rules' do
      report = Fabricate.build(:report, category: :violation, rule_ids: [-1])
      expect(report.valid?).to be false
      expect(report).to model_have_error_on_field(:rule_ids)
    end

    it 'is invalid if it references rules but category is not "violation"' do
      rule = Fabricate(:rule)
      report = Fabricate.build(:report, category: :spam, rule_ids: rule.id)
      expect(report.valid?).to be false
      expect(report).to model_have_error_on_field(:rule_ids)
    end
  end
end