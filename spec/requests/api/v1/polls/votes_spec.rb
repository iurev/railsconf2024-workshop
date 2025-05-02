# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Polls Votes' do
  let_it_be(:user)   { Fabricate(:user) }
  let_it_be(:scopes) { 'write:statuses' }
  let_it_be(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'POST /api/v1/polls/:poll_id/votes' do
    let_it_be(:poll) { Fabricate(:poll) }

    before do
      post "/api/v1/polls/#{poll.id}/votes", params: { choices: %w(1) }, headers: headers
    end

    it 'creates a vote', :aggregate_failures do
      expect(response).to have_http_status(200)

      expect(vote).to_not be_nil
      expect(vote.choice).to eq 1

      expect(poll.reload.cached_tallies).to eq [0, 1]
    end

    private

    def vote
      poll.votes.where(account: user.account).first
    end
  end
end