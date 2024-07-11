# frozen_string_literal: true

require 'rails_helper'
require 'webauthn/fake_client'

describe Admin::Users::TwoFactorAuthenticationsController do
  render_views

  let_it_be(:user) { Fabricate(:user) }
  let_it_be(:admin) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:fake_client) { WebAuthn::FakeClient.new('http://test.host') }

  before do
    sign_in admin, scope: :user
  end

  describe 'DELETE #destroy' do
    context 'when user has OTP enabled' do
      before do
        user.update(otp_required_for_login: true)
      end

      it 'redirects to admin account page' do
        delete :destroy, params: { user_id: user.id }

        user.reload
        expect(user.otp_enabled?).to be false
        expect(response).to redirect_to(admin_account_path(user.account_id))
      end
    end

    context 'when user has OTP and WebAuthn enabled' do
      let_it_be(:webauthn_credential) do
        user.update(otp_required_for_login: true, webauthn_id: WebAuthn.generate_user_id)
        public_key_credential = WebAuthn::Credential.from_create(fake_client.create)
        Fabricate(:webauthn_credential,
                  user_id: user.id,
                  external_id: public_key_credential.id,
                  public_key: public_key_credential.public_key,
                  nickname: 'Security Key')
      end

      it 'redirects to admin account page' do
        delete :destroy, params: { user_id: user.id }

        user.reload
        expect(user.otp_enabled?).to be false
        expect(user.webauthn_enabled?).to be false
        expect(response).to redirect_to(admin_account_path(user.account_id))
      end
    end
  end
end