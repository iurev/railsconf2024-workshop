# frozen_string_literal: true

require 'rails_helper'

describe 'Accounts Lists API' do
  let_it_be(:user)    { Fabricate(:user) }
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:list)    { Fabricate(:list, account: user.account) }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  let(:scopes)   { 'read:lists' }
  let(:headers)  { { 'Authorization' => "Bearer #{token.token}" } }

  let_it_be(:setup) do
    user.account.follow!(account)
    list.accounts << account
  end

  describe 'GET /api/v1/accounts/lists' do
    it 'returns http success' do
      get "/api/v1/accounts/#{account.id}/lists", headers: headers

      expect(response).to have_http_status(200)
    end
  end
end