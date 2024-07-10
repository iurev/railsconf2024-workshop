# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V2 Filters Keywords' do
  let_it_be(:user) { Fabricate(:user) }
  let_it_be(:other_user) { Fabricate(:user) }
  let_it_be(:filter) { Fabricate(:custom_filter, account: user.account) }
  let_it_be(:other_filter) { Fabricate(:custom_filter, account: other_user.account) }

  shared_context 'with access token' do |scopes|
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
    let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }
  end

  describe 'GET /api/v2/filters/:filter_id/keywords' do
    include_context 'with access token', 'read:filters'
    let_it_be(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    it 'returns http success' do
      get "/api/v2/filters/#{filter.id}/keywords", headers: headers
      expect(response).to have_http_status(200)
      expect(body_as_json)
        .to contain_exactly(
          include(id: keyword.id.to_s)
        )
    end

    context "when trying to access another's user filters" do
      it 'returns http not found' do
        get "/api/v2/filters/#{other_filter.id}/keywords", headers: headers
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST /api/v2/filters/:filter_id/keywords' do
    include_context 'with access token', 'write:filters'

    it 'creates a filter', :aggregate_failures do
      post "/api/v2/filters/#{filter.id}/keywords", headers: headers, params: { keyword: 'magic', whole_word: false }

      expect(response).to have_http_status(200)

      json = body_as_json
      expect(json[:keyword]).to eq 'magic'
      expect(json[:whole_word]).to be false

      filter.reload
      expect(filter.keywords.pluck(:keyword)).to eq ['magic']
    end

    context "when trying to add to another another's user filters" do
      it 'returns http not found' do
        post "/api/v2/filters/#{other_filter.id}/keywords", headers: headers, params: { keyword: 'magic', whole_word: false }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /api/v2/filters/keywords/:id' do
    include_context 'with access token', 'read:filters'
    let_it_be(:keyword) { Fabricate(:custom_filter_keyword, keyword: 'foo', whole_word: false, custom_filter: filter) }

    it 'responds with the keyword', :aggregate_failures do
      get "/api/v2/filters/keywords/#{keyword.id}", headers: headers

      expect(response).to have_http_status(200)

      json = body_as_json
      expect(json[:keyword]).to eq 'foo'
      expect(json[:whole_word]).to be false
    end

    context "when trying to access another user's filter keyword" do
      let_it_be(:other_keyword) { Fabricate(:custom_filter_keyword, custom_filter: other_filter) }

      it 'returns http not found' do
        get "/api/v2/filters/keywords/#{other_keyword.id}", headers: headers
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'PUT /api/v2/filters/keywords/:id' do
    include_context 'with access token', 'write:filters'
    let_it_be(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    it 'updates the keyword', :aggregate_failures do
      put "/api/v2/filters/keywords/#{keyword.id}", headers: headers, params: { keyword: 'updated' }

      expect(response).to have_http_status(200)

      expect(keyword.reload.keyword).to eq 'updated'
    end

    context "when trying to update another user's filter keyword" do
      let_it_be(:other_keyword) { Fabricate(:custom_filter_keyword, custom_filter: other_filter) }

      it 'returns http not found' do
        put "/api/v2/filters/keywords/#{other_keyword.id}", headers: headers, params: { keyword: 'updated' }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE /api/v2/filters/keywords/:id' do
    include_context 'with access token', 'write:filters'
    let!(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    it 'destroys the keyword', :aggregate_failures do
      delete "/api/v2/filters/keywords/#{keyword.id}", headers: headers

      expect(response).to have_http_status(200)

      expect { keyword.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    context "when trying to update another user's filter keyword" do
      let_it_be(:other_keyword) { Fabricate(:custom_filter_keyword, custom_filter: other_filter) }

      it 'returns http not found' do
        delete "/api/v2/filters/keywords/#{other_keyword.id}", headers: headers
        expect(response).to have_http_status(404)
      end
    end
  end
end