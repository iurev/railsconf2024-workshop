# frozen_string_literal: true

require 'rails_helper'

describe Admin::RelationshipsController, :account do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { account_id: account.id }

      expect(response).to have_http_status(:success)
    end
  end
end
