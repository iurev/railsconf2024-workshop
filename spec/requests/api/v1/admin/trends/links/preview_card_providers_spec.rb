# frozen_string_literal: true

require 'rails_helper'

describe 'API V1 Admin Trends Links Preview Card Providers' do
  let_it_be(:admin_role) { UserRole.find_by(name: 'Admin') }
  let_it_be(:user)   { Fabricate(:user, role: admin_role) }
  let_it_be(:scopes) { 'admin:read admin:write' }
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:preview_card_provider) { Fabricate(:preview_card_provider) }

  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/admin/trends/links/publishers' do
    it 'returns http success' do
      get '/api/v1/admin/trends/links/publishers', params: { account_id: account.id, limit: 2 }, headers: headers

      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /api/v1/admin/trends/links/publishers/:id/approve' do
    context 'with correct permissions' do
      before do
        post "/api/v1/admin/trends/links/publishers/#{preview_card_provider.id}/approve", headers: headers
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses' do
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:statuses') }
    end

    it_behaves_like 'forbidden for wrong role', '' do
      let(:user_role) { UserRole.find_by(name: 'User') }
      let(:user) { Fabricate(:user, role: user_role) }
    end
  end

  describe 'POST /api/v1/admin/trends/links/publishers/:id/reject' do
    context 'with correct permissions' do
      before do
        post "/api/v1/admin/trends/links/publishers/#{preview_card_provider.id}/reject", headers: headers
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses' do
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:statuses') }
    end

    it_behaves_like 'forbidden for wrong role', '' do
      let(:user_role) { UserRole.find_by(name: 'User') }
      let(:user) { Fabricate(:user, role: user_role) }
    end
  end
end