# frozen_string_literal: true

require 'rails_helper'

describe 'Accounts Familiar Followers API' do
  let_it_be(:user)     { Fabricate(:user) }
  let_it_be(:token)    { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:follows') }
  let_it_be(:account)  { Fabricate(:account) }
  let(:headers)        { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/accounts/familiar_followers' do
    it 'returns http success' do
      get '/api/v1/accounts/familiar_followers', params: { account_id: account.id, limit: 2 }, headers: headers

      expect(response).to have_http_status(200)
    end

    context 'when there are duplicate account IDs in the params' do
      let_it_be(:account_a) { Fabricate(:account) }
      let_it_be(:account_b) { Fabricate(:account) }

      it 'removes duplicate account IDs from params' do
        account_ids = [account_a, account_b, account_b, account_a, account_a].map { |a| a.id.to_s }
        get '/api/v1/accounts/familiar_followers', params: { id: account_ids }, headers: headers

        expect(body_as_json.pluck(:id)).to contain_exactly(account_a.id.to_s, account_b.id.to_s)
      end
    end
  end
end