# frozen_string_literal: true

require 'rails_helper'

describe Settings::Exports::BlockedDomainsController do
  render_views

  describe 'GET #index' do
    let_it_be(:account) { Fabricate(:account, domain: 'example.com') }
    let_it_be(:user) { Fabricate(:user, account: account) }
    let_it_be(:account_domain_block) { Fabricate(:account_domain_block, domain: 'example.com', account: account) }

    it 'returns a csv of the domains' do
      sign_in user, scope: :user
      get :index, format: :csv

      expect(response.body).to eq "example.com\n"
    end
  end
end