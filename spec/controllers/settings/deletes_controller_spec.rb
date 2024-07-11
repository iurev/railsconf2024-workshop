# frozen_string_literal: true

require 'rails_helper'

describe Settings::DeletesController do
  render_views

  let_it_be(:user) { Fabricate(:user, password: 'petsmoldoggos') }
  let_it_be(:suspended_user) { Fabricate(:user, account_attributes: { suspended_at: Time.now.utc }) }

  describe 'GET #show' do
    shared_examples 'returns expected response' do |status, cache_control|
      it "returns http #{status} with expected cache control headers", :aggregate_failures do
        expect(response).to have_http_status(status)
        expect(response.headers['Cache-Control']).to include(cache_control)
      end
    end

    context 'when signed in' do
      before do
        sign_in user, scope: :user
        get :show
      end

      it_behaves_like 'returns expected response', 200, 'private, no-store'

      context 'when suspended' do
        before do
          sign_in suspended_user, scope: :user
          get :show
        end

        it_behaves_like 'returns expected response', 403, 'private, no-store'
      end
    end

    context 'when not signed in' do
      before { get :show }

      it 'redirects to sign in page' do
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when signed in' do
      before do
        sign_in user, scope: :user
      end

      context 'with correct password' do
        before do
          delete :destroy, params: { form_delete_confirmation: { password: 'petsmoldoggos' } }
        end

        it 'removes user record and redirects', :aggregate_failures, sidekiq: :inline do
          expect(response).to redirect_to '/auth/sign_in'
          expect(User.find_by(id: user.id)).to be_nil
          expect(user.account.reload).to be_suspended
          expect(CanonicalEmailBlock.block?(user.email)).to be false
        end

        context 'when suspended' do
          before do
            sign_in suspended_user, scope: :user
            delete :destroy, params: { form_delete_confirmation: { password: 'petsmoldoggos' } }
          end

          it 'returns http forbidden' do
            expect(response).to have_http_status(403)
          end
        end
      end

      context 'with incorrect password' do
        before do
          delete :destroy, params: { form_delete_confirmation: { password: 'blaze420' } }
        end

        it 'redirects back to confirmation page' do
          expect(response).to redirect_to settings_delete_path
        end
      end
    end

    context 'when not signed in' do
      before { delete :destroy }

      it 'redirects to sign in page' do
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end
end