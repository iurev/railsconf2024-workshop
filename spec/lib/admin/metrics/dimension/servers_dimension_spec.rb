# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Dimension::ServersDimension do
  subject { described_class.new(start_at, end_at, limit, params) }

  let_it_be(:start_at) { 2.days.ago }
  let_it_be(:end_at) { Time.now.utc }
  let_it_be(:limit) { 10 }
  let_it_be(:params) { ActionController::Parameters.new }

  describe '#data' do
    let_it_be(:domain) { 'host.example' }
    let_it_be(:alice) { Fabricate(:account, domain: domain) }
    let_it_be(:bob) { Fabricate(:account) }

    before(:all) do
      Fabricate :status, account: alice, created_at: 1.day.ago
      Fabricate :status, account: alice, created_at: 30.days.ago
      Fabricate :status, account: bob, created_at: 1.day.ago
    end

    it 'returns domains with status counts' do
      expect(subject.data.size)
        .to eq(2)
      expect(subject.data.map(&:symbolize_keys))
        .to contain_exactly(
          include(key: domain, value: '1'),
          include(key: Rails.configuration.x.local_domain, value: '1')
        )
    end
  end
end