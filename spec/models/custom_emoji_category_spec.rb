# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomEmojiCategory, :aggregate_failures do
  describe 'validations' do
    let_it_be(:invalid_category) { described_class.new(name: nil) }

    it 'validates name presence' do
      expect(invalid_category).to_not be_valid
      expect(invalid_category).to model_have_error_on_field(:name)
    end
  end
end