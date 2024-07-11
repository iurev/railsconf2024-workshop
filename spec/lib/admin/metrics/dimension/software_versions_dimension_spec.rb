# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Dimension::SoftwareVersionsDimension do
  let_it_be(:start_at) { 2.days.ago }
  let_it_be(:end_at) { Time.now.utc }
  let_it_be(:limit) { 10 }
  let_it_be(:params) { ActionController::Parameters.new }

  subject { described_class.new(start_at, end_at, limit, params) }

  describe '#data' do
    it 'reports on the running software' do
      expect(subject.data.map(&:symbolize_keys))
        .to include(
          include(key: 'mastodon', value: Mastodon::Version.to_s),
          include(key: 'ruby', value: include(RUBY_VERSION))
        )
    end
  end
end