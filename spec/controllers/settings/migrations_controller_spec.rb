# frozen_string_literal: true

require 'rails_helper'

describe Settings::MigrationsController do
  render_views

  shared_examples 'authenticate user' do
    it 'redirects to sign_in page' do
      expect(subject).to redirect_to new_user_session_path
    end
  end

  describe 'GET #show' do
    context 'when user is not sign in' do
      subject { get :show }

      it_behaves_like 'authenticate user'
    end

    context 'when user is sign in' do
      subject { get :show }

      let_it_be(:moved_to_account) { nil }
      let_it_be(:user) { Fabricate(:user) }
      let_it_be(:account) { Fabricate(:account, user: user, moved_to_account: moved_to_account) }

      before do
        sign_in user, scope: :user
      end

      context 'when user does not have moved to account' do
        it 'renders show page' do
          expect(subject).to have_http_status 200
          expect(subject).to render_template :show
        end
      end

      context 'when user has a moved to account' do
        let_it_be(:moved_to_account) { Fabricate(:account) }

        it 'renders show page' do
          expect(subject).to have_http_status 200
          expect(subject).to render_template :show
        end
      end
    end
  end

  describe 'POST #create' do
    context 'when user is not sign in' do
      subject { post :create }

      it_behaves_like 'authenticate user'
    end

    context 'when user is signed in' do
      let_it_be(:user) { Fabricate(:user, password: '12345678') }
      let_it_be(:account) { Fabricate(:account, user: user) }

      before do
        sign_in user, scope: :user
      end

      context 'when migration account is changed' do
        let_it_be(:acct) { Fabricate(:account, also_known_as: [ActivityPub::TagManager.instance.uri_for(account)]) }

        subject { post :create, params: { account_migration: { acct: acct.acct, current_password: '12345678' } } }

        it 'updates moved to account' do
          expect(subject).to redirect_to settings_migration_path
          expect(account.reload.moved_to_account_id).to eq acct.id
        end
      end

      context 'when acct is the current account' do
        subject { post :create, params: { account_migration: { acct: account.acct, current_password: '12345678' } } }

        it 'does not update the moved account', :aggregate_failures do
          subject

          expect(account.reload.moved_to_account_id).to be_nil
          expect(response).to render_template :show
        end
      end

      context 'when target account does not reference the account being moved from' do
        let_it_be(:acct) { Fabricate(:account, also_known_as: []) }

        subject { post :create, params: { account_migration: { acct: acct.acct, current_password: '12345678' } } }

        it 'does not update the moved account', :aggregate_failures do
          subject

          expect(account.reload.moved_to_account_id).to be_nil
          expect(response).to render_template :show
        end
      end

      context 'when a recent migration already exists' do
        let_it_be(:acct) { Fabricate(:account, also_known_as: [ActivityPub::TagManager.instance.uri_for(account)]) }

        before do
          moved_to = Fabricate(:account, also_known_as: [ActivityPub::TagManager.instance.uri_for(account)])
          account.migrations.create!(acct: moved_to.acct)
        end

        subject { post :create, params: { account_migration: { acct: acct.acct, current_password: '12345678' } } }

        it 'does not update the moved account', :aggregate_failures do
          subject

          expect(account.reload.moved_to_account_id).to be_nil
          expect(response).to render_template :show
        end
      end
    end
  end
end