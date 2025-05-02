# frozen_string_literal: true

require 'rails_helper'

describe Importer::PublicStatusesIndexImporter do
  describe 'import!' do
    let(:pool) { Concurrent::FixedThreadPool.new(5) }
    let(:importer) { described_class.new(batch_size: 123, executor: pool) }

    let_it_be(:account) { Fabricate(:account, indexable: true) }
    let_it_be(:status) { Fabricate(:status, account: account) }

    it 'indexes relevant statuses' do
      expect { importer.import! }.to update_index(PublicStatusesIndex)
    end
  end
end