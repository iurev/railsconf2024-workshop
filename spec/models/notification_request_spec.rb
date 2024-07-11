# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationRequest do
  describe '#reconsider_existence!' do
    let_it_be(:account) { Fabricate(:account) }
    let_it_be(:from_account) { Fabricate(:account) }
    let(:notification_request) { Fabricate(:notification_request, account: account, from_account: from_account, dismissed: dismissed) }
    let(:dismissed) { false }

    subject { notification_request }

    context 'when there are remaining notifications' do
      before do
        Fabricate(:notification, account: account, from_account: from_account, activity: Fabricate(:status, account: from_account), filtered: true)
        subject.reconsider_existence!
      end

      it 'leaves request intact' do
        expect(subject.destroyed?).to be false
      end

      it 'updates notifications_count' do
        expect(subject.notifications_count).to eq 1
      end
    end

    context 'when there are no notifications' do
      before do
        subject.reconsider_existence!
      end

      context 'when dismissed' do
        let(:dismissed) { true }

        it 'leaves request intact' do
          expect(subject.destroyed?).to be false
        end
      end

      it 'removes the request' do
        expect(subject.destroyed?).to be true
      end
    end
  end
end