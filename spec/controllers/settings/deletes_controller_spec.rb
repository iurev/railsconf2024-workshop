# frozen_string_literal: true

require 'rails_helper'

describe Settings::DeletesController do
  render_views

  let_it_be(:user) { Fabricate(:user, password: 'petsmoldoggos') }

  describe 'GET #show' do
    context 'when signed in' do
      before do
        sign_in user, scope: :user
        get :show
      end

      it 'renders confirmation page with private cache control headers', :aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.headers['Cache-Control']).to include('private, no-store')
      end

      context 'when suspended' do
        let(:suspended_user) { Fabricate(:user, account_attributes: { suspended_at: Time.now.utc }) }

        before do
          sign_in suspended_user, scope: :user
          get :show
        end

        it 'returns http forbidden with private cache control headers', :aggregate_failures do
          expect(response).to have_http_status(403)
          expect(response.headers['Cache-Control']).to include('private, no-store')
        end
      end
    end

    context 'when not signed in' do
      it 'redirects' do
        get :show
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
          let(:suspended_user) { Fabricate(:user, account_attributes: { suspended_at: Time.now.utc }) }

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
      it 'redirects' do
        delete :destroy
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end
end