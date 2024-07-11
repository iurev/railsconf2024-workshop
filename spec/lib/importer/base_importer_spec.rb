# frozen_string_literal: true

require 'rails_helper'

describe Importer::BaseImporter do
  describe 'import!' do
    let_it_be(:pool) { Concurrent::FixedThreadPool.new(5) }
    let_it_be(:importer) { described_class.new(batch_size: 123, executor: pool) }

    it 'raises an error' do
      expect { importer.import! }.to raise_error(NotImplementedError)
    end
  end
end