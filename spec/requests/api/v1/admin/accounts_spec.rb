# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Accounts' do
  let_it_be(:role)    { UserRole.find_by(name: 'Admin') }
  let_it_be(:user)    { Fabricate(:user, role: role) }
  let_it_be(:scopes)  { 'admin:read:accounts admin:write:accounts' }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  let_it_be(:remote_account)    { Fabricate(:account, domain: 'example.org') }
  let_it_be(:suspended_account) { Fabricate(:account, suspended: true) }
  let_it_be(:disabled_account)  { Fabricate(:user, disabled: true).account }
  let_it_be(:pending_account)   { Fabricate(:user, approved: false).account }
  let_it_be(:admin_account)     { user.account }

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: wrong_scope) }
    let(:wrong_headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }

    it 'returns http forbidden' do
      subject.call(wrong_headers)
      expect(response).to have_http_status(403)
    end
  end

  shared_examples 'forbidden for wrong role' do |wrong_role|
    let(:wrong_role_user) { Fabricate(:user, role: UserRole.find_by(name: wrong_role || 'User')) }
    let(:wrong_role_token) { Fabricate(:accessible_access_token, resource_owner_id: wrong_role_user.id, scopes: scopes) }
    let(:wrong_headers) { { 'Authorization' => "Bearer #{wrong_role_token.token}" } }

    it 'returns http forbidden' do
      subject.call(wrong_headers)
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET /api/v1/admin/accounts' do
    subject { -> (h = headers) { get '/api/v1/admin/accounts', headers: h, params: params } }

    shared_examples 'a successful request' do
      it 'returns the correct accounts', :aggregate_failures do
        subject.call
        expect(response).to have_http_status(200)
        expect(body_as_json.pluck(:id)).to match_array(expected_results.map { |a| a.id.to_s })
      end
    end

    let(:params) { {} }

    it_behaves_like 'forbidden for wrong scope', 'read read:accounts admin:write admin:write:accounts'
    it_behaves_like 'forbidden for wrong role', ''

    context 'when requesting active local staff accounts' do
      let(:expected_results) { [admin_account] }
      let(:params)           { { active: 'true', local: 'true', staff: 'true' } }

      it_behaves_like 'a successful request'
    end

    context 'when requesting remote accounts from a specified domain' do
      let(:expected_results) { [remote_account] }
      let(:params)           { { by_domain: 'example.org', remote: 'true' } }

      before do
        Fabricate(:account, domain: 'foo.bar')
      end

      it_behaves_like 'a successful request'
    end

    context 'when requesting suspended accounts' do
      let(:expected_results) { [suspended_account] }
      let(:params)           { { suspended: 'true' } }

      before do
        Fabricate(:account, domain: 'foo.bar', suspended: true)
      end

      it_behaves_like 'a successful request'
    end

    context 'when requesting disabled accounts' do
      let(:expected_results) { [disabled_account] }
      let(:params)           { { disabled: 'true' } }

      it_behaves_like 'a successful request'
    end

    context 'when requesting pending accounts' do
      let(:expected_results) { [pending_account] }
      let(:params)           { { pending: 'true' } }

      before do
        pending_account.user.update(approved: false)
      end

      it_behaves_like 'a successful request'
    end

    context 'when no parameter is given' do
      let(:expected_results) { [disabled_account, pending_account, admin_account] }

      it_behaves_like 'a successful request'
    end

    context 'with limit param' do
      let(:params) { { limit: 2 } }

      it 'returns only the requested number of accounts', :aggregate_failures do
        subject.call
        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(params[:limit])
      end
    end
  end

  describe 'GET /api/v1/admin/accounts/:id' do
    subject { -> (h = headers) { get "/api/v1/admin/accounts/#{account.id}", headers: h } }

    let(:account) { Fabricate(:account) }

    it_behaves_like 'forbidden for wrong scope', 'read read:accounts admin:write admin:write:accounts'
    it_behaves_like 'forbidden for wrong role', ''

    it 'returns the requested account successfully', :aggregate_failures do
      subject.call
      expect(response).to have_http_status(200)
      expect(body_as_json).to match(
        a_hash_including(id: account.id.to_s, username: account.username, email: account.user.email)
      )
    end

    context 'when the account is not found' do
      it 'returns http not found' do
        get '/api/v1/admin/accounts/-1', headers: headers
        expect(response).to have_http_status(404)
      end
    end
  end

  # ... Rest of the tests follow the same pattern ...

  private

  def latest_admin_action_log
    Admin::ActionLog.last
  end
end