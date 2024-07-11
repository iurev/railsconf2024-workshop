# frozen_string_literal: true
# aiptimize started

require 'rails_helper'

describe Admin::Webhooks::SecretsController do
  render_views

  let(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }

  before do
    sign_in user, scope: :user
  end

  describe 'POST #rotate' do
    let(:webhook) { Fabricate(:webhook) }

    it 'returns http success' do
      post :rotate, params: { webhook_id: webhook.id }

      expect(response).to redirect_to(admin_webhook_path(webhook))
    end
  end
end
