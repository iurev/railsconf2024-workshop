# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Confirmations' do
  let_it_be(:user) { Fabricate(:user, confirmed_at: nil) }
  let_it_be(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:accounts write:accounts') }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'POST /api/v1/emails/confirmations' do
    subject do
      post '/api/v1/emails/confirmations', headers: headers, params: params
    end

    let(:params) { {} }

    context 'with wrong scope' do
      let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read read:accounts') }
      let(:headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }

      it_behaves_like 'forbidden for wrong scope', 'read read:accounts'
    end

    context 'with an oauth token' do
      context 'when user was created by a different application' do
        let(:different_app_user) { Fabricate(:user, confirmed_at: nil, created_by_application: Fabricate(:application)) }
        let(:different_app_token) { Fabricate(:accessible_access_token, resource_owner_id: different_app_user.id, scopes: 'read:accounts write:accounts') }
        let(:headers) { { 'Authorization' => "Bearer #{different_app_token.token}" } }

        it 'returns http forbidden' do
          subject

          expect(response).to have_http_status(403)
        end
      end

      context 'when user was created by the same application' do
        before do
          user.update(created_by_application: token.application)
        end

        context 'when the account is already confirmed' do
          before { user.update(confirmed_at: Time.now.utc) }

          it 'returns http forbidden' do
            subject

            expect(response).to have_http_status(403)
          end

          context 'when user changed e-mail and has not confirmed it' do
            before do
              user.update(email: 'foo@bar.com')
            end

            it 'returns http success' do
              subject

              expect(response).to have_http_status(200)
            end
          end
        end

        context 'when the account is unconfirmed' do
          it 'returns http success' do
            subject

            expect(response).to have_http_status(200)
          end
        end

        context 'with email param' do
          let(:params) { { email: 'foo@bar.com' } }

          it "updates the user's e-mail address", :aggregate_failures do
            subject

            expect(response).to have_http_status(200)
            expect(user.reload.unconfirmed_email).to eq('foo@bar.com')
          end
        end

        context 'with invalid email param' do
          let(:params) { { email: 'invalid' } }

          it 'returns http unprocessable entity' do
            subject

            expect(response).to have_http_status(422)
          end
        end
      end
    end

    context 'without an oauth token' do
      let(:headers) { {} }

      it 'returns http unauthorized' do
        subject

        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /api/v1/emails/check_confirmation' do
    subject do
      get '/api/v1/emails/check_confirmation', headers: headers
    end

    context 'with wrong scope' do
      let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }
      let(:headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }

      it_behaves_like 'forbidden for wrong scope', 'write'
    end

    context 'with an oauth token' do
      context 'when the account is not confirmed' do
        it 'returns the confirmation status successfully', :aggregate_failures do
          subject

          expect(response).to have_http_status(200)
          expect(body_as_json).to be false
        end
      end

      context 'when the account is confirmed' do
        before { user.update(confirmed_at: Time.now.utc) }

        it 'returns the confirmation status successfully', :aggregate_failures do
          subject

          expect(response).to have_http_status(200)
          expect(body_as_json).to be true
        end
      end
    end

    context 'with an authentication cookie' do
      let(:headers) { {} }

      before do
        sign_in user, scope: :user
      end

      context 'when the account is not confirmed' do
        it 'returns the confirmation status successfully', :aggregate_failures do
          subject

          expect(response).to have_http_status(200)
          expect(body_as_json).to be false
        end
      end

      context 'when the account is confirmed' do
        before { user.update(confirmed_at: Time.now.utc) }

        it 'returns the confirmation status successfully', :aggregate_failures do
          subject

          expect(response).to have_http_status(200)
          expect(body_as_json).to be true
        end
      end
    end

    context 'without an oauth token and an authentication cookie' do
      let(:headers) { {} }

      it 'returns http unauthorized' do
        subject

        expect(response).to have_http_status(401)
      end
    end
  end
end