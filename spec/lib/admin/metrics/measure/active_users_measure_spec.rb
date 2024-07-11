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

      before_all do
        travel_to(2.days.ago) do
          3.times { |i| ActivityTracker.record('activity:logins', users[i].id) }
        end
        travel_to(1.day.ago) do
          2.times { |i| ActivityTracker.record('activity:logins', users[i + 3].id) }
        end
        travel_to(0.days.ago) do
          ActivityTracker.record('activity:logins', users.last.id)
        end
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
    end
  end
end