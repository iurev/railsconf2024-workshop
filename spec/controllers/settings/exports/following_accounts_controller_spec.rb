# frozen_string_literal: true

require 'rails_helper'

describe Settings::Exports::FollowingAccountsController do
  render_views

  describe 'GET #index' do
    let_it_be(:user) { Fabricate(:user) }
    let_it_be(:followed_account) { Fabricate(:account, username: 'username', domain: 'domain') }

    before do
      user.account.follow!(followed_account)
      sign_in user, scope: :user
    end

    it 'returns a csv of the following accounts' do
      get :index, format: :csv

      expect(response.body).to eq "Account address,Show boosts,Notify on new posts,Languages\nusername@domain,true,false,\n"
    end
  end
end