# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vacuum::MediaAttachmentsVacuum do
  subject { described_class.new(retention_period) }

  let(:retention_period) { 7.days }
  let_it_be(:remote_status) { Fabricate(:status, account: Fabricate(:account, domain: 'example.com')) }
  let_it_be(:local_status) { Fabricate(:status) }

  describe '#perform' do
    let_it_be(:old_remote_media) { Fabricate(:media_attachment, remote_url: 'https://example.com/foo.png', status: remote_status, created_at: (7.days + 1.day).ago, updated_at: (7.days + 1.day).ago) }
    let_it_be(:old_local_media) { Fabricate(:media_attachment, status: local_status, created_at: (7.days + 1.day).ago, updated_at: (7.days + 1.day).ago) }
    let_it_be(:new_remote_media) { Fabricate(:media_attachment, remote_url: 'https://example.com/foo.png', status: remote_status) }
    let_it_be(:new_local_media) { Fabricate(:media_attachment, status: local_status) }
    let_it_be(:old_unattached_media) { Fabricate(:media_attachment, account_id: nil, created_at: 10.days.ago) }
    let_it_be(:new_unattached_media) { Fabricate(:media_attachment, account_id: nil, created_at: 1.hour.ago) }

    before_all do
      described_class.new(7.days).perform
    end

    it 'deletes cache of remote media attachments past the retention period' do
      expect(old_remote_media.reload.file).to be_blank
    end

    it 'does not touch local media attachments past the retention period' do
      expect(old_local_media.reload.file).to_not be_blank
    end

    it 'does not delete cache of remote media attachments within the retention period' do
      expect(new_remote_media.reload.file).to_not be_blank
    end

    it 'does not touch local media attachments within the retention period' do
      expect(new_local_media.reload.file).to_not be_blank
    end

    it 'deletes unattached media attachments past TTL' do
      expect { old_unattached_media.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not delete unattached media attachments within TTL' do
      expect(new_unattached_media.reload).to be_persisted
    end
  end
end