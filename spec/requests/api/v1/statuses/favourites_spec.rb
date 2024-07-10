# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Favourites' do
  let_it_be(:user)    { Fabricate(:user) }
  let_it_be(:scopes)  { 'write:favourites' }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'POST /api/v1/statuses/:status_id/favourite' do
    subject do
      post "/api/v1/statuses/#{status.id}/favourite", headers: headers
    end

    let_it_be(:status) { Fabricate(:status) }

    it_behaves_like 'forbidden for wrong scope', 'read read:favourites' do
      let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read read:favourites') }
      let(:headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }
    end

    context 'with public status' do
      it 'favourites the status successfully', :aggregate_failures do
        subject

        expect(response).to have_http_status(200)
        expect(user.account.favourited?(status)).to be true
      end

      it 'returns json with updated attributes' do
        subject

        expect(body_as_json).to match(
          a_hash_including(id: status.id.to_s, favourites_count: 1, favourited: true)
        )
      end
    end

    context 'with private status of not-followed account' do
      let_it_be(:private_status) { Fabricate(:status, visibility: :private) }

      it 'returns http not found' do
        post "/api/v1/statuses/#{private_status.id}/favourite", headers: headers

        expect(response).to have_http_status(404)
      end
    end

    context 'with private status of followed account' do
      let_it_be(:followed_account) { Fabricate(:account) }
      let_it_be(:private_status) { Fabricate(:status, account: followed_account, visibility: :private) }

      before do
        user.account.follow!(followed_account)
      end

      it 'favourites the status successfully', :aggregate_failures do
        post "/api/v1/statuses/#{private_status.id}/favourite", headers: headers

        expect(response).to have_http_status(200)
        expect(user.account.favourited?(private_status)).to be true
      end
    end

    context 'without an authorization header' do
      it 'returns http unauthorized' do
        post "/api/v1/statuses/#{status.id}/favourite", headers: {}

        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /api/v1/statuses/:status_id/unfavourite' do
    subject do
      post "/api/v1/statuses/#{status.id}/unfavourite", headers: headers
    end

    let_it_be(:status) { Fabricate(:status) }

    it_behaves_like 'forbidden for wrong scope', 'read read:favourites' do
      let(:wrong_scope_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read read:favourites') }
      let(:headers) { { 'Authorization' => "Bearer #{wrong_scope_token.token}" } }
    end

    context 'with public status' do
      before do
        FavouriteService.new.call(user.account, status)
      end

      it 'unfavourites the status successfully', :aggregate_failures, sidekiq: :inline do
        subject

        expect(response).to have_http_status(200)

        expect(user.account.favourited?(status)).to be false
      end

      it 'returns json with updated attributes' do
        subject

        expect(body_as_json).to match(
          a_hash_including(id: status.id.to_s, favourites_count: 0, favourited: false)
        )
      end
    end

    context 'when the requesting user was blocked by the status author' do
      before do
        FavouriteService.new.call(user.account, status)
        status.account.block!(user.account)
      end

      it 'unfavourites the status successfully', :aggregate_failures, sidekiq: :inline do
        subject

        expect(response).to have_http_status(200)

        expect(user.account.favourited?(status)).to be false
      end

      it 'returns json with updated attributes' do
        subject

        expect(body_as_json).to match(
          a_hash_including(id: status.id.to_s, favourites_count: 0, favourited: false)
        )
      end
    end

    context 'when status is not favourited' do
      it 'returns http success' do
        subject

        expect(response).to have_http_status(200)
      end
    end

    context 'with private status that was not favourited' do
      let_it_be(:private_status) { Fabricate(:status, visibility: :private) }

      it 'returns http not found' do
        post "/api/v1/statuses/#{private_status.id}/unfavourite", headers: headers

        expect(response).to have_http_status(404)
      end
    end
  end
end