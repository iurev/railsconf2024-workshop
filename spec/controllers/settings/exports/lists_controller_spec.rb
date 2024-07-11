# frozen_string_literal: true

require 'rails_helper'

describe Settings::Exports::ListsController do
  render_views

  describe 'GET #index' do
    let_it_be(:account) { Fabricate(:account) }
    let_it_be(:user) { Fabricate(:user, account: account) }
    let_it_be(:list) { Fabricate(:list, account: account, title: 'The List') }
    let_it_be(:list_account) { Fabricate(:list_account, list: list, account: account) }

    it 'returns a csv of the domains' do
      sign_in user, scope: :user
      get :index, format: :csv

      expect(response.body).to match 'The List'
    end
  end
end