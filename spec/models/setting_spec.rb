# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Setting do
  describe '#to_param' do
    let_it_be(:var) { 'var' }
    let_it_be(:setting) { Fabricate(:setting, var: var) }

    it 'returns setting.var' do
      expect(setting.to_param).to eq var
    end
  end

  describe '.[]' do
    let_it_be(:key)         { 'key' }
    let_it_be(:cache_key)   { 'cache-key' }
    let_it_be(:cache_value) { 'cache-value' }
    let_it_be(:default_value) { 'default_value' }
    let_it_be(:default_settings) { { key => default_value } }

    before(:all) do
      Setting.class_eval do
        def self.cache_key(key)
          'cache-key'
        end

        def self.default_settings
          { 'key' => 'default_value' }
        end
      end
    end

    after(:all) do
      Setting.class_eval do
        class << self
          remove_method :cache_key
          remove_method :default_settings
        end
      end
    end

    context 'when Rails.cache does not exist' do
      before(:all) do
        Rails.cache.delete(cache_key)
      end

      context 'when the setting has been saved to database' do
        let_it_be(:saved_setting) { Fabricate(:setting, var: key, value: 42) }

        it 'returns the value from database' do
          callback = double
          allow(callback).to receive(:call)

          ActiveSupport::Notifications.subscribed callback, 'sql.active_record' do
            expect(described_class[key]).to eq 42
          end

          expect(callback).to have_received(:call)
        end
      end

      context 'when the setting has not been saved to database' do
        it 'returns default_settings[key]' do
          expect(described_class[key]).to be default_settings[key]
        end
      end
    end

    context 'when Rails.cache exists' do
      before(:all) do
        Rails.cache.write(cache_key, cache_value)
      end

      after(:all) do
        Rails.cache.delete(cache_key)
      end

      it 'does not query the database' do
        callback = double
        allow(callback).to receive(:call)
        ActiveSupport::Notifications.subscribed callback, 'sql.active_record' do
          described_class[key]
        end
        expect(callback).to_not have_received(:call)
      end

      it 'returns the cached value' do
        expect(described_class[key]).to eq cache_value
      end
    end
  end
end