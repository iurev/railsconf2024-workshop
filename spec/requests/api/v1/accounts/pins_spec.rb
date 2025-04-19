# frozen_string_literal: true

require 'rails_helper'

describe 'Accounts Pins API' do
  let_it_be(:user)     { Fabricate(:user) }
  let_it_be(:kevin)    { Fabricate(:user) }
  let_it_be(:scopes)   { 'write:accounts' }
  let_it_be(:token)    { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:headers)  { { 'Authorization' => "Bearer #{token.token}" } }

  before_all do
    kevin.account.followers << user.account
  end

  describe 'POST /api/v1/accounts/:account_id/pin' do
    subject { post "/api/v1/accounts/#{kevin.account.id}/pin", headers: headers }

    it 'creates account_pin', :aggregate_failures do
      expect do
        subject
      end.to change { AccountPin.where(account: user.account, target_account: kevin.account).count }.by(1)
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/unpin' do
    subject { post "/api/v1/accounts/#{kevin.account.id}/unpin", headers: headers }

    let_it_be(:account_pin) { Fabricate(:account_pin, account: user.account, target_account: kevin.account) }

    it 'destroys account_pin', :aggregate_failures do
      expect do
        subject
      end.to change { AccountPin.where(account: user.account, target_account: kevin.account).count }.by(-1)
      expect(response).to have_http_status(200)
    end
  end
end