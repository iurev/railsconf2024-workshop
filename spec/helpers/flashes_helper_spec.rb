# frozen_string_literal: true

require 'rails_helper'

describe FlashesHelper do
  describe 'user_facing_flashes' do
    let_it_be(:flash) do
      {
        alert: 'an alert',
        error: 'an error',
        notice: 'a notice',
        success: 'a success',
        not_user_facing: 'a not user facing flash'
      }
    end

    before do
      # rubocop:disable Rails/I18nLocaleTexts
      allow(helper).to receive(:flash).and_return(flash)
      # rubocop:enable Rails/I18nLocaleTexts
    end

    it 'returns user facing flashes' do
      expect(helper.user_facing_flashes).to eq(
        'alert' => 'an alert',
        'error' => 'an error',
        'notice' => 'a notice',
        'success' => 'a success'
      )
    end
  end
end