# frozen_string_literal: true

require 'rails_helper'

describe Auth::ConfirmationsController do
  render_views

  before_all do
    request.env['devise.mapping'] = Devise.mappings[:user]
    allow(BootstrapTimelineWorker).to receive(:perform_async)
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET #show' do
    context 'when user is unconfirmed' do
      let_it_be(:user) { Fabricate(:user, confirmation_token: 'foobar', confirmed_at: nil) }

      before do
        get :show, params: { confirmation_token: 'foobar' }
      end

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'queues up bootstrapping of home timeline' do
        expect(BootstrapTimelineWorker).to have_received(:perform_async).with(user.account_id)
      end
    end

    context 'when user is unconfirmed and unapproved' do
      let_it_be(:user) { Fabricate(:user, confirmation_token: 'foobar', confirmed_at: nil, approved: false) }

      before do
        get :show, params: { confirmation_token: 'foobar' }
      end

      it 'redirects to login and confirms user' do
        expect(response).to redirect_to(new_user_session_path)
        expect(user.reload.confirmed_at).to_not be_nil
      end
    end

    context 'when user is already confirmed' do
      let_it_be(:user) { Fabricate(:user) }

      before do
        sign_in(user, scope: :user)
        get :show, params: { confirmation_token: 'foobar' }
      end

      it 'redirects to root path' do
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is already confirmed but unapproved' do
      let_it_be(:user) { Fabricate(:user, approved: false) }

      before do
        sign_in(user, scope: :user)
        get :show, params: { confirmation_token: 'foobar' }
      end

      it 'redirects to settings' do
        expect(response).to redirect_to(edit_user_registration_path)
      end
    end

    context 'when user is updating email' do
      let_it_be(:user) { Fabricate(:user, confirmation_token: 'foobar', unconfirmed_email: 'new-email@example.com') }

      before do
        get :show, params: { confirmation_token: 'foobar' }
      end

      it 'redirects to login and confirms email' do
        expect(response).to redirect_to(new_user_session_path)
        expect(user.reload.unconfirmed_email).to be_nil
      end

      it 'does not queue up bootstrapping of home timeline' do
        expect(BootstrapTimelineWorker).to_not have_received(:perform_async)
      end
    end
  end
end