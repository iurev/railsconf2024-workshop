# frozen_string_literal: true

require 'rails_helper'

describe Admin::Webhooks::SecretsController, :user do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:webhook) { Fabricate(:webhook) }

  before do
    sign_in user, scope: :user
  end

  describe 'POST #rotate' do
    it 'returns http success' do
      post :rotate, params: { webhook_id: webhook.id }

      expect(response).to redirect_to(admin_webhook_path(webhook))
    end
  end
end