# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Measure::ActiveUsersMeasure do
  subject { described_class.new(start_at, end_at, params) }

  let(:start_at) { 2.days.ago }
  let(:end_at)   { Time.now.utc }
  let(:params) { ActionController::Parameters.new }

  describe '#data' do
    context 'with activity tracking records' do
      let_it_be(:users) { Fabricate.times(6, :user) }

      before do
        3.times do |i|
          travel_to(2.days.ago) { record_login_activity(users[i]) }
        end
        2.times do |i|
          travel_to(1.day.ago) { record_login_activity(users[i + 3]) }
        end
        travel_to(0.days.ago) { record_login_activity(users.last) }
      end

      it 'returns correct activity tracker counts' do
        expect(subject.data.size)
          .to eq(3)
        expect(subject.data.map(&:symbolize_keys))
          .to contain_exactly(
            include(date: 2.days.ago.midnight.to_time, value: '3'),
            include(date: 1.day.ago.midnight.to_time, value: '2'),
            include(date: 0.days.ago.midnight.to_time, value: '1')
          )
      end

      def record_login_activity(user)
        ActivityTracker.record('activity:logins', user.id)
      end
    end
  end
end