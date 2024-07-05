# frozen_string_literal: true

require 'rails_helper'

describe Admin::Metrics::Measure::InstanceReportsMeasure do
  subject { described_class.new(start_at, end_at, params) }

  let_it_be(:domain) { 'example.com' }
  let_it_be(:start_at) { 2.days.ago }
  let_it_be(:end_at) { Time.now.utc }

  let(:params) { ActionController::Parameters.new(domain: domain) }

  shared_context 'with reports' do
    before_all do
      Fabricate(:report, target_account: Fabricate(:account, domain: domain))
      Fabricate(:report, target_account: Fabricate(:account, domain: domain))

      Fabricate(:report, target_account: Fabricate(:account, domain: "foo.#{domain}"))
      Fabricate(:report, target_account: Fabricate(:account, domain: "foo.#{domain}"))
      Fabricate(:report, target_account: Fabricate(:account, domain: "bar.#{domain}"))
    end
  end

  describe '#total' do
    include_context 'with reports'

    context 'without include_subdomains' do
      it 'returns the expected number of accounts' do
        expect(subject.total).to eq 2
      end
    end

    context 'with include_subdomains' do
      let(:params) { ActionController::Parameters.new(domain: domain, include_subdomains: 'true') }

      it 'returns the expected number of accounts' do
        expect(subject.total).to eq 5
      end
    end
  end

  describe '#data' do
    include_context 'with reports'

    it 'returns correct instance_reports counts' do
      expect(subject.data.size)
        .to eq(3)
      expect(subject.data.map(&:symbolize_keys))
        .to contain_exactly(
          include(date: 2.days.ago.midnight.to_time, value: '0'),
          include(date: 1.day.ago.midnight.to_time, value: '0'),
          include(date: 0.days.ago.midnight.to_time, value: '2')
        )
    end
  end
end