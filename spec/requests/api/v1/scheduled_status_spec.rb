# frozen_string_literal: true

require 'rails_helper'

describe 'Scheduled Statuses' do
  let_it_be(:user) { Fabricate(:user) }
  let(:scopes) { 'read:statuses' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/scheduled_statuses' do
    context 'when not authorized' do
      it 'returns http unauthorized' do
        get api_v1_scheduled_statuses_path

        expect(response)
          .to have_http_status(401)
      end
    end

    context 'with wrong scope' do
      let(:scopes) { 'write write:statuses' }

      before do
        get api_v1_scheduled_statuses_path, headers: headers
      end

      it_behaves_like 'forbidden for wrong scope', 'write write:statuses'
    end

    context 'with correct scope' do
      context 'without scheduled statuses' do
        it 'returns http success without json' do
          get api_v1_scheduled_statuses_path, headers: headers

          expect(response)
            .to have_http_status(200)

          expect(body_as_json)
            .to_not be_present
        end
      end

      context 'with scheduled statuses' do
        let!(:scheduled_status) { Fabricate(:scheduled_status, account: user.account) }

        it 'returns http success and status json' do
          get api_v1_scheduled_statuses_path, headers: headers

          expect(response)
            .to have_http_status(200)

          expect(body_as_json)
            .to be_present
            .and have_attributes(
              first: include(id: scheduled_status.id.to_s)
            )
        end
      end
    end
  end
end