# frozen_string_literal: true

require 'rails_helper'

describe 'Accounts Identity Proofs API', :account do
  let_it_be(:user)     { Fabricate(:user) }
  let_it_be(:token)    { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:scopes)   { 'read:accounts' }
  let_it_be(:headers)  { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/accounts/identity_proofs' do
    it 'returns http success' do
      get "/api/v1/accounts/#{account.id}/identity_proofs", params: { limit: 2 }, headers: headers

      expect(response).to have_http_status(200)
    end
  end
end