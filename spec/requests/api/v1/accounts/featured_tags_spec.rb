# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'account featured tags API' do
  let_it_be(:user)     { Fabricate(:user) }
  let_it_be(:token)    { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:scopes)   { 'read:accounts' }
  let_it_be(:headers)  { { 'Authorization' => "Bearer #{token.token}" } }
  let_it_be(:account)  { Fabricate(:account) }

  describe 'GET /api/v1/accounts/:id/featured_tags' do
    subject do
      get "/api/v1/accounts/#{account.id}/featured_tags", headers: headers
    end

    before_all do
      account.featured_tags.create!(name: 'foo')
      account.featured_tags.create!(name: 'bar')
    end

    it 'returns the expected tags', :aggregate_failures do
      subject

      expect(response).to have_http_status(200)
      expect(body_as_json).to contain_exactly(a_hash_including({
        name: 'bar',
        url: "https://cb6e6126.ngrok.io/@#{account.username}/tagged/bar",
      }), a_hash_including({
        name: 'foo',
        url: "https://cb6e6126.ngrok.io/@#{account.username}/tagged/foo",
      }))
    end

    context 'when the account is remote' do
      it 'returns the expected tags', :aggregate_failures do
        subject

        expect(response).to have_http_status(200)
        expect(body_as_json).to contain_exactly(a_hash_including({
          name: 'bar',
          url: "https://cb6e6126.ngrok.io/@#{account.pretty_acct}/tagged/bar",
        }), a_hash_including({
          name: 'foo',
          url: "https://cb6e6126.ngrok.io/@#{account.pretty_acct}/tagged/foo",
        }))
      end
    end
  end
end