# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vacuum::SystemKeysVacuum do
  let_it_be(:expired_system_key) { Fabricate(:system_key, created_at: (SystemKey::ROTATION_PERIOD * 4).ago) }
  let_it_be(:current_system_key) { Fabricate(:system_key) }

  subject(:vacuum) { described_class.new }

  describe '#perform' do
    before do
      vacuum.perform
    end

    it 'deletes the expired key' do
      expect { expired_system_key.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'does not delete the current key' do
      expect { current_system_key.reload }.to_not raise_error
    end
  end
end