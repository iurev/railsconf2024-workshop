# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationPolicy do
  describe '#summarize!' do
    let_it_be(:notification_policy) { Fabricate(:notification_policy) }
    let_it_be(:sender) { Fabricate(:account) }

    before_all do
      Fabricate.times(2, :notification, account: notification_policy.account, activity: Fabricate(:status, account: sender), filtered: true)
      Fabricate(:notification_request, account: notification_policy.account, from_account: sender)
    end

    before do
      notification_policy.summarize!
    end

    it 'sets pending_requests_count' do
      expect(notification_policy.pending_requests_count).to eq 1
    end

    it 'sets pending_notifications_count' do
      expect(notification_policy.pending_notifications_count).to eq 2
    end
  end
end