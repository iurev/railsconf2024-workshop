# frozen_string_literal: true

require 'rails_helper'

describe 'Admin Retention' do
  let_it_be(:user)    { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:account) { Fabricate(:account) }

  describe 'GET /api/v1/admin/retention' do
    context 'when not authorized' do
      it 'returns http forbidden' do
        post '/api/v1/admin/retention', params: { account_id: account.id, limit: 2 }

        expect(response)
          .to have_http_status(403)
      end
    end

    context 'with correct scope' do
      let(:scopes) { 'admin:read' }

      before do
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        @headers = { 'Authorization' => "Bearer #{token.token}" }
      end

      it 'returns http success and status json' do
        post '/api/v1/admin/retention', params: { account_id: account.id, limit: 2 }, headers: @headers

        expect(response)
          .to have_http_status(200)

        expect(body_as_json)
          .to be_an(Array)
      end
    end
  end
end