# frozen_string_literal: true

require 'rails_helper'

describe 'API V1 Admin Trends Statuses' do
  let_it_be(:role)   { UserRole.find_by(name: 'Admin') }
  let_it_be(:user)   { Fabricate(:user, role: role) }
  let_it_be(:scopes) { 'admin:read admin:write' }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:status)  { Fabricate(:status) }

  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/admin/trends/statuses' do
    it 'returns http success' do
      get '/api/v1/admin/trends/statuses', params: { account_id: account.id, limit: 2 }, headers: headers
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /api/v1/admin/trends/statuses/:id/approve' do
    context 'with correct permissions' do
      it 'returns http success' do
        post "/api/v1/admin/trends/statuses/#{status.id}/approve", headers: headers
        expect(response).to have_http_status(200)
      end
    end

    context 'with incorrect permissions' do
      it_behaves_like 'forbidden for wrong scope', 'write:statuses' do
        let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }
        let(:wrong_headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }
        let(:api_call) { -> { post "/api/v1/admin/trends/statuses/#{status.id}/approve", headers: wrong_headers } }
      end

      it_behaves_like 'forbidden for wrong role', '' do
        let(:wrong_role_user) { Fabricate(:user, role: UserRole.find_by(name: 'User')) }
        let(:wrong_role_token) { Fabricate(:accessible_access_token, resource_owner_id: wrong_role_user.id, scopes: scopes) }
        let(:wrong_headers) { { 'Authorization' => "Bearer #{wrong_role_token.token}" } }
        let(:api_call) { -> { post "/api/v1/admin/trends/statuses/#{status.id}/approve", headers: wrong_headers } }
      end
    end
  end

  describe 'POST /api/v1/admin/trends/statuses/:id/unapprove' do
    context 'with correct permissions' do
      it 'returns http success' do
        post "/api/v1/admin/trends/statuses/#{status.id}/reject", headers: headers
        expect(response).to have_http_status(200)
      end
    end

    context 'with incorrect permissions' do
      it_behaves_like 'forbidden for wrong scope', 'write:statuses' do
        let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }
        let(:wrong_headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }
        let(:api_call) { -> { post "/api/v1/admin/trends/statuses/#{status.id}/reject", headers: wrong_headers } }
      end

      it_behaves_like 'forbidden for wrong role', '' do
        let(:wrong_role_user) { Fabricate(:user, role: UserRole.find_by(name: 'User')) }
        let(:wrong_role_token) { Fabricate(:accessible_access_token, resource_owner_id: wrong_role_user.id, scopes: scopes) }
        let(:wrong_headers) { { 'Authorization' => "Bearer #{wrong_role_token.token}" } }
        let(:api_call) { -> { post "/api/v1/admin/trends/statuses/#{status.id}/reject", headers: wrong_headers } }
      end
    end
  end
end