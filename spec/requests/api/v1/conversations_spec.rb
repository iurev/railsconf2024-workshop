# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Conversations' do
  let_it_be(:user) { Fabricate(:user, account_attributes: { username: 'alice' }) }
  let_it_be(:other) { Fabricate(:user) }
  let(:scopes) { 'read:statuses' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/conversations' do
    before do
      user.account.follow!(other.account)
      PostStatusService.new.call(other.account, text: 'Hey @alice', visibility: 'direct')
      PostStatusService.new.call(user.account, text: 'Hey, nobody here', visibility: 'direct')
    end

    it 'returns pagination headers', :aggregate_failures, sidekiq: :inline do
      get '/api/v1/conversations', params: { limit: 1 }, headers: headers

      expect(response).to have_http_status(200)
      expect(response.headers['Link'].links.size).to eq(2)
    end

    it 'returns conversations', :aggregate_failures, sidekiq: :inline do
      get '/api/v1/conversations', headers: headers

      expect(body_as_json.size).to eq 2
      expect(body_as_json[0][:accounts].size).to eq 1
    end

    context 'with since_id' do
      context 'when requesting old posts' do
        it 'returns conversations', sidekiq: :inline do
          get '/api/v1/conversations', params: { since_id: Mastodon::Snowflake.id_at(1.hour.ago, with_random: false) }, headers: headers

          expect(body_as_json.size).to eq 2
        end
      end

      context 'when requesting posts in the future' do
        it 'returns no conversation' do
          get '/api/v1/conversations', params: { since_id: Mastodon::Snowflake.id_at(1.hour.from_now, with_random: false) }, headers: headers

          expect(body_as_json.size).to eq 0
        end
      end
    end
  end
end