# frozen_string_literal: true

require 'rails_helper'

describe Settings::MigrationsController do
  render_views

  let(:current_user) { Fabricate(:account, moved_to_account: current_moved_to).user }
  before { sign_in current_user, scope: :user }

  shared_examples 'authenticate user' do
    subject { get :show }
    
    it 'redirects to sign_in page' do
      expect(subject).to redirect_to new_user_session_path
    end
  end

  describe 'GET #show' do
    let(:current_moved_to) { nil }

    subject { get :show }

    it 'renders show page' do
      expect(subject).to have_http_status 200
      expect(subject).to render_template :show
    end
  end

  describe 'POST #create' do
    let(:current_moved_to) { nil }
    let(:account) { Fabricate(:account, also_known_as: [ActivityPub::TagManager.instance.uri_for(user.account)]) }
    
    subject { post :create, params: { account_migration: { acct: account.acct, current_password: '12345678' } } }
    
    context 'when migration account is changed' do
      let(:account) { Fabricate(:account, also_known_as: [ActivityPub::TagManager.instance.uri_for(user.account)]) }
      
      it 'updates moved to account' do
        expect(subject).to redirect_to settings_migration_path
        expect(current_user.account.reload.moved_to_account_id).to eq account.id
      end
    end
  end
end