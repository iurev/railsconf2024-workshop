# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vacuum::StatusesVacuum do
  subject { described_class.new(retention_period) }

  let(:retention_period) { 7.days }

  let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com') }

  describe '#perform' do
    let_it_be(:remote_status_old) { Fabricate(:status, account: remote_account, created_at: 9.days.ago) }
    let_it_be(:remote_status_recent) { Fabricate(:status, account: remote_account, created_at: 5.days.ago) }
    let_it_be(:local_status_old) { Fabricate(:status, created_at: 9.days.ago) }
    let_it_be(:local_status_recent) { Fabricate(:status, created_at: 5.days.ago) }

    before do
      subject.perform
    end

    it 'deletes remote statuses past the retention period' do
      expect { remote_status_old.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'does not delete local statuses past the retention period' do
      expect { local_status_old.reload }.to_not raise_error
    end

    it 'does not delete remote statuses within the retention period' do
      expect { remote_status_recent.reload }.to_not raise_error
    end

    it 'does not delete local statuses within the retention period' do
      expect { local_status_recent.reload }.to_not raise_error
    end
  end
end