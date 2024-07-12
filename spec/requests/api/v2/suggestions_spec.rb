# frozen_string_literal: true

require 'rails_helper'

describe 'Suggestions API', :account do
  let_it_be(:user)    { Fabricate(:user) }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }
  let_it_be(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v2/suggestions' do
    let_it_be(:bob)  { Fabricate(:account) }
    let_it_be(:jeff) { Fabricate(:account) }

    before_all do
      Setting.bootstrap_timeline_accounts = [bob, jeff].map(&:acct).join(',')
    end

    it 'returns the expected suggestions' do
      get '/api/v2/suggestions', headers: headers

      expect(response).to have_http_status(200)

      expect(body_as_json).to match_array(
        [bob, jeff].map do |account|
          hash_including({
            source: 'staff',
            sources: ['featured'],
            account: hash_including({ id: account.id.to_s }),
          })
        end
      )
    end
  end
end