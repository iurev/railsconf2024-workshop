# frozen_string_literal: true

require 'rails_helper'

describe 'Home' do
  let_it_be(:user)    { Fabricate(:user) }
  let_it_be(:scopes)  { 'read:statuses' }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/timelines/home' do
    subject do
      get '/api/v1/timelines/home', headers: headers, params: params
    end

    let(:params) { {} }

    context 'with wrong scope' do
      let(:scopes) { 'write write:statuses' }

      it 'returns http forbidden' do
        subject
        expect(response).to have_http_status(403)
      end
    end

    context 'when the timeline is available' do
      let_it_be(:bob) { Fabricate(:account) }
      let_it_be(:tim) { Fabricate(:account) }
      let_it_be(:ana) { Fabricate(:account) }

      before do
        user.account.follow!(bob)
        user.account.follow!(ana)
        Fabricate(:status, account: bob, text: 'New toot from bob.')
        Fabricate(:status, account: tim, text: 'New toot from tim.')
        Fabricate(:status, account: ana, text: 'New toot from ana.')
      end

      let(:home_statuses) { Status.where(account: [bob, ana]).order(id: :desc) }

      it 'returns http success' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'returns the statuses of followed users' do
        subject
        expect(body_as_json.pluck(:id)).to match_array(home_statuses.map { |status| status.id.to_s })
      end

      context 'with limit param' do
        let(:params) { { limit: 1 } }

        it 'returns only the requested number of statuses' do
          subject
          expect(body_as_json.size).to eq(params[:limit])
        end

        it 'sets the correct pagination headers' do
          subject
          expect(response.headers['Link']).to include('rel="next"')
          expect(response.headers['Link']).to include('rel="prev"')
        end
      end
    end

    context 'when the timeline is regenerating' do
      let(:timeline) { instance_double(HomeFeed, regenerating?: true, get: []) }

      before do
        allow(HomeFeed).to receive(:new).and_return(timeline)
      end

      it 'returns http partial content' do
        subject
        expect(response).to have_http_status(206)
      end
    end

    context 'without an authorization header' do
      let(:headers) { {} }

      it 'returns http unauthorized' do
        subject
        expect(response).to have_http_status(401)
      end
    end

    context 'without a user context' do
      let_it_be(:token) { Fabricate(:accessible_access_token, resource_owner_id: nil, scopes: scopes) }

      it 'returns http unprocessable entity' do
        subject
        expect(response).to have_http_status(422)
        expect(response.headers['Link']).to be_nil
      end
    end
  end
end