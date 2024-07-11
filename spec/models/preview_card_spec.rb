# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreviewCard do
  let_it_be(:preview_card) { described_class.new }

  describe 'validations' do
    describe 'urls' do
      it 'allows http schemes' do
        preview_card.url = 'http://example.host/path'
        expect(preview_card).to be_valid
      end

      it 'allows https schemes' do
        preview_card.url = 'https://example.host/path'
        expect(preview_card).to be_valid
      end

      it 'does not allow javascript: schemes' do
        preview_card.url = 'javascript:alert()'
        expect(preview_card).to_not be_valid
        expect(preview_card).to model_have_error_on_field(:url)
      end
    end
  end
end