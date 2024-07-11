# frozen_string_literal: true

require 'rails_helper'

describe OneTimeKey do
  describe 'validations' do
    let_it_be(:one_time_key) { Fabricate.build(:one_time_key) }

    context 'with an invalid signature' do
      before { one_time_key.signature = 'wrong!' }

      it 'is invalid' do
        expect(one_time_key).to_not be_valid
      end
    end

    context 'with an invalid key' do
      before { one_time_key.key = 'wrong!' }

      it 'is invalid' do
        expect(one_time_key).to_not be_valid
      end
    end
  end
end