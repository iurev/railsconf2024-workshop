# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Dimension::SpaceUsageDimension do
  subject { described_class.new(start_at, end_at, limit, params) }

  let_it_be(:start_at) { 2.days.ago }
  let_it_be(:end_at) { Time.now.utc }
  let_it_be(:limit) { 10 }
  let_it_be(:params) { ActionController::Parameters.new }

  describe '#data' do
    it 'reports on used storage space' do
      expect(subject.data.map(&:symbolize_keys))
        .to include(
          include(key: 'media', value: /\d/),
          include(key: 'postgresql', value: /\d/),
          include(key: 'redis', value: /\d/)
        )
    end
  end
end