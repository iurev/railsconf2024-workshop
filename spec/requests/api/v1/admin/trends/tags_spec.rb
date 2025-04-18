# frozen_string_literal: true

require 'rails_helper'

describe 'API V1 Admin Trends Tags' do
  let_it_be(:role)   { UserRole.find_by(name: 'Admin') }
  let_it_be(:user)   { Fabricate(:user, role: role) }
  let_it_be(:scopes) { 'admin:read admin:write' }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:tag)     { Fabricate(:tag) }
  let_it_be(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/admin/trends/tags' do
    it 'returns http success' do
      get '/api/v1/admin/trends/tags', params: { account_id: account.id, limit: 2 }, headers: headers

      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /api/v1/admin/trends/tags/:id/approve' do
    before do
      post "/api/v1/admin/trends/tags/#{tag.id}/approve", headers: headers
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', ''

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /api/v1/admin/trends/tags/:id/reject' do
    before do
      post "/api/v1/admin/trends/tags/#{tag.id}/reject", headers: headers
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', ''

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end
  end
end