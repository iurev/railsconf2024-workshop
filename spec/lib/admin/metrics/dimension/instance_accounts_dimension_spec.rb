# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Dimension::InstanceAccountsDimension do
  subject { described_class.new(start_at, end_at, limit, params) }

  let_it_be(:start_at) { 2.days.ago }
  let_it_be(:end_at) { Time.now.utc }
  let_it_be(:limit) { 10 }
  let_it_be(:domain) { 'host.example' }
  let_it_be(:alice) { Fabricate(:account, domain: domain) }
  let_it_be(:bob) { Fabricate(:account) }

  let(:params) { ActionController::Parameters.new(domain: domain) }

  describe '#data' do
    before_all do
      Fabricate(:follow, target_account: alice)
      Fabricate(:follow, target_account: bob)
      Fabricate(:status, account: alice)
      Fabricate(:status, account: bob)
    end

    it 'returns instances with follow counts' do
      expect(subject.data.size)
        .to eq(1)
      expect(subject.data.map(&:symbolize_keys))
        .to contain_exactly(
          include(key: alice.username, value: '1')
        )
    end
  end
end