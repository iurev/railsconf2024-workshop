# frozen_string_literal: true

require 'rails_helper'

describe 'Pins' do
  let_it_be(:user)    { Fabricate(:user) }
  let_it_be(:scopes)  { 'write:accounts' }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let_it_be(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'POST /api/v1/statuses/:status_id/pin' do
    subject do
      post "/api/v1/statuses/#{status.id}/pin", headers: headers
    end

    let_it_be(:status) { Fabricate(:status, account: user.account) }

    it_behaves_like 'forbidden for wrong scope', 'read read:accounts'

    context 'when the status is public' do
      it 'pins the status successfully', :aggregate_failures do
        subject

        expect(response).to have_http_status(200)
        expect(user.account.pinned?(status)).to be true
      end

      it 'return json with updated attributes' do
        subject

        expect(body_as_json).to match(
          a_hash_including(id: status.id.to_s, pinned: true)
        )
      end
    end

    context 'when the status is private' do
      let_it_be(:private_status) { Fabricate(:status, account: user.account, visibility: :private) }

      it 'pins the status successfully', :aggregate_failures do
        post "/api/v1/statuses/#{private_status.id}/pin", headers: headers

        expect(response).to have_http_status(200)
        expect(user.account.pinned?(private_status)).to be true
      end
    end

    context 'when the status belongs to somebody else' do
      let_it_be(:other_status) { Fabricate(:status) }

      it 'returns http unprocessable entity' do
        post "/api/v1/statuses/#{other_status.id}/pin", headers: headers

        expect(response).to have_http_status(422)
      end
    end

    context 'when the status does not exist' do
      it 'returns http not found' do
        post '/api/v1/statuses/-1/pin', headers: headers

        expect(response).to have_http_status(404)
      end
    end

    context 'without an authorization header' do
      it 'returns http unauthorized' do
        post "/api/v1/statuses/#{status.id}/pin", headers: {}

        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /api/v1/statuses/:status_id/unpin' do
    subject do
      post "/api/v1/statuses/#{status.id}/unpin", headers: headers
    end

    let_it_be(:status) { Fabricate(:status, account: user.account) }

    context 'when the status is pinned' do
      before do
        Fabricate(:status_pin, status: status, account: user.account)
      end

      it 'unpins the status successfully', :aggregate_failures do
        subject

        expect(response).to have_http_status(200)
        expect(user.account.pinned?(status)).to be false
      end

      it 'return json with updated attributes' do
        subject

        expect(body_as_json).to match(
          a_hash_including(id: status.id.to_s, pinned: false)
        )
      end
    end

    context 'when the status is not pinned' do
      it 'returns http success' do
        subject

        expect(response).to have_http_status(200)
      end
    end

    context 'when the status does not exist' do
      it 'returns http not found' do
        post '/api/v1/statuses/-1/unpin', headers: headers

        expect(response).to have_http_status(404)
      end
    end

    context 'without an authorization header' do
      it 'returns http unauthorized' do
        post "/api/v1/statuses/#{status.id}/unpin", headers: {}

        expect(response).to have_http_status(401)
      end
    end
  end
end