# frozen_string_literal: true

require 'rails_helper'

describe Marker do
  let_it_be(:marker) { described_class.new }

  describe 'validations' do
    describe 'timeline' do
      it 'must be included in valid list' do
        marker.timeline = 'not real timeline'

        expect(marker).to_not be_valid
        expect(marker).to model_have_error_on_field(:timeline)
      end
    end
  end
end