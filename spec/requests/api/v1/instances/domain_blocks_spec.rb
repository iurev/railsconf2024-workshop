# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Domain Blocks' do
  let_it_be(:domain_block) { Fabricate(:domain_block) }

  describe 'GET /api/v1/instance/domain_blocks' do
    context 'with domain blocks set to all' do
      before { Setting.show_domain_blocks = 'all' }

      it 'returns http success' do
        get api_v1_instance_domain_blocks_path

        expect(response)
          .to have_http_status(200)

        expect(body_as_json)
          .to be_present
          .and(be_an(Array))
          .and(have_attributes(size: 1))
      end
    end

    context 'with domain blocks set to users' do
      before { Setting.show_domain_blocks = 'users' }

      it 'returns http not found' do
        get api_v1_instance_domain_blocks_path

        expect(response)
          .to have_http_status(404)
      end
    end

    context 'with domain blocks set to disabled' do
      before { Setting.show_domain_blocks = 'disabled' }

      it 'returns http not found' do
        get api_v1_instance_domain_blocks_path

        expect(response)
          .to have_http_status(404)
      end
    end
  end
end