# frozen_string_literal: true

require 'rails_helper'

context 'when visited anonymously' do
  around do |example|
    old = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    example.run

    ActionController::Base.allow_forgery_protection = old
  end

  let_it_be(:alice) { Fabricate(:account, username: 'alice', display_name: 'Alice') }
  let_it_be(:status) { Fabricate(:status, account: alice, text: 'Hello World') }

  describe 'account pages' do
    it 'do not set cookies' do
      get '/@alice'

      expect(response.cookies).to be_empty
    end
  end

  describe 'status pages' do
    it 'do not set cookies' do
      get short_account_status_url(alice, status)

      expect(response.cookies).to be_empty
    end
  end

  describe 'the /about page' do
    it 'does not set cookies' do
      get '/about'

      expect(response.cookies).to be_empty
    end
  end
end