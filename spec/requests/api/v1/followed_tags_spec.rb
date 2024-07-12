# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Followed tags' do
  let_it_be(:user)    { Fabricate(:user) }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:follows') }
  let_it_be(:headers) { { 'Authorization' => "Bearer #{token.token}" } }
  let_it_be(:tag_follows) { Fabricate.times(2, :tag_follow, account: user.account) }

  describe 'GET /api/v1/followed_tags' do
    subject do
      get '/api/v1/followed_tags', headers: headers, params: params
    end

    let(:params) { {} }

    let(:expected_response) do
      tag_follows.map do |tag_follow|
        a_hash_including(name: tag_follow.tag.name, following: true)
      end
    end

    before do
      Fabricate(:tag_follow)
    end

    it_behaves_like 'forbidden for wrong scope', 'write write:follows'

    it 'returns http success' do
      subject

      expect(response).to have_http_status(:success)
    end

    it 'returns the followed tags correctly' do
      subject

      expect(body_as_json).to match_array(expected_response)
    end

    context 'with limit param' do
      let(:params) { { limit: 1 } }

      it 'returns only the requested number of follow tags' do
        subject

        expect(body_as_json.size).to eq(params[:limit])
      end

      it 'sets the correct pagination headers' do
        subject

        expect(response)
          .to include_pagination_headers(
            prev: api_v1_followed_tags_url(limit: params[:limit], since_id: tag_follows.last.id),
            next: api_v1_followed_tags_url(limit: params[:limit], max_id: tag_follows.last.id)
          )
      end
    end
  end
end