# frozen_string_literal: true
require 'rails_helper'

describe Settings::MigrationsController do
  render_views
  
  shared_examples_for 'authenticate user' do
    it 'redirects to sign_in page' do
      expect(subject).to redirect_to new_user_session_path
    end
  end

  describe 'GET #show' do
    before { get :show }
    
    context 'when user is not signed in' do
      subject { response }
      
      it_behaves_like 'authenticate user'
    end
  
    context 'when user is signed in' do
      let(:user) { Fabricate(:account, moved_to_account: moved_to_account).user }
    
      before { sign_in(user, scope: :user) }
    
      subject { response }
      
      context 'when user does not have a moved to account' do
        let(:moved_to_account) { nil }
        
        it 'renders show page' do
          expect(subject).to have_http_status 200
          expect(subject).to render_template :show
        end
      end
    
      context 'when user has a moved to account' do
        let(:moved_to_account) { Fabricate(:account) }
        
        it 'renders show page' do
          expect(subject).to have_http_status 200
          expect(subject).to render_template :show
        end
      end
    end
  end

  describe 'POST #create' do
    before { post :create, params: { account_migration: { acct: acct.acct, current_password: '12345678'} } }
    
    let(:user) { Fabricate(:user, password: '12345678') }
    let(:acct) { user.account }
  
    context 'when user is not signed in' do
      subject { response }
      
      it_behaves_like 'authenticate user'
    end
    
    context 'when user is signed in' do
      before { sign_in(user, scope: :user) }
  
      subject { response }
      
      context 'when the migration account is changed' do
        let(:acct) { Fabricate(:account, also_known_as: [ActivityPub::TagManager.instance.uri_for(user.account)]) }
        
        it 'updates moved to account', :aggregate_failures do
          expect(subject).to redirect_to settings_migration_path
          expect(user.reload.acct).not_to eq acct.acct
        end
      end
      
      context 'when the migration account is not changed' do
        let(:acct) { user.account }
        
        it 'does not update the moved to account', :aggregate_failures do
          expect(subject).to render_template :show
          expect(user.reload.acct).to eq acct.acct
        end
      end
    end
  end
end