# frozen_string_literal: true

require 'rails_helper'

describe Admin::AccountActionsController do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:account) { Fabricate(:account) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new, params: { account_id: account.id }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'records the account action' do
      expect do
        post :create, params: { account_id: account.id, admin_account_action: { type: 'silence' } }
      end.to change { account.strikes.count }.by(1)

      expect(response).to redirect_to(admin_account_path(account.id))
    end
  end
end