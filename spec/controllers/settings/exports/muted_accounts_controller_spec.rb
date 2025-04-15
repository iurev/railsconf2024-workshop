# frozen_string_literal: true

require 'rails_helper'

describe Settings::Exports::MutedAccountsController do
  render_views

  describe 'GET #index' do
    let_it_be(:user) { Fabricate(:user) }
    let_it_be(:muted_account) { Fabricate(:account, username: 'username', domain: 'domain') }

    before do
      user.account.mute!(muted_account)
      sign_in user, scope: :user
    end

    it 'returns a csv of the muting accounts' do
      get :index, format: :csv

      expect(response.body).to eq "Account address,Hide notifications\nusername@domain,true\n"
    end
  end
end