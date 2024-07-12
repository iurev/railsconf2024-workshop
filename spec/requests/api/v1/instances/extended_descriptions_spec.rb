# frozen_string_literal: true
# aiptimize started

require 'rails_helper'

RSpec.describe 'Extended Descriptions' do
  describe 'GET /api/v1/instance/extended_description' do
    it 'returns http success' do
      get api_v1_instance_extended_description_path

      expect(response)
        .to have_http_status(200)

      expect(body_as_json)
        .to be_present
        .and include(:content)
    end
  end
end
