# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Filters' do
  let_it_be(:user) { Fabricate(:user) }
  let_it_be(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/filters' do
    let_it_be(:filter) { Fabricate(:custom_filter, account: user.account) }
    let_it_be(:custom_filter_keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    before do
      token.update!(scopes: 'read:filters')
    end

    it 'returns http success' do
      get '/api/v1/filters', headers: headers
      expect(response).to have_http_status(200)
      expect(body_as_json)
        .to contain_exactly(
          include(id: custom_filter_keyword.id.to_s)
        )
    end
  end

  describe 'POST /api/v1/filters' do
    before do
      token.update!(scopes: 'write:filters')
    end

    let(:irreversible) { true }
    let(:whole_word)   { false }

    before do
      post '/api/v1/filters', params: { phrase: 'magic', context: %w(home), irreversible: irreversible, whole_word: whole_word }, headers: headers
    end

    it 'creates a filter', :aggregate_failures do
      filter = user.account.custom_filters.first

      expect(response).to have_http_status(200)
      expect(filter).to_not be_nil
      expect(filter.keywords.pluck(:keyword, :whole_word)).to eq [['magic', whole_word]]
      expect(filter.context).to eq %w(home)
      expect(filter.irreversible?).to be irreversible
      expect(filter.expires_at).to be_nil
    end

    context 'with different parameters' do
      let(:irreversible) { false }
      let(:whole_word)   { true }

      it 'creates a filter', :aggregate_failures do
        filter = user.account.custom_filters.first

        expect(response).to have_http_status(200)
        expect(filter).to_not be_nil
        expect(filter.keywords.pluck(:keyword, :whole_word)).to eq [['magic', whole_word]]
        expect(filter.context).to eq %w(home)
        expect(filter.irreversible?).to be irreversible
        expect(filter.expires_at).to be_nil
      end
    end
  end

  describe 'GET /api/v1/filters/:id' do
    let_it_be(:filter)  { Fabricate(:custom_filter, account: user.account) }
    let_it_be(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    before do
      token.update!(scopes: 'read:filters')
    end

    it 'returns http success' do
      get "/api/v1/filters/#{keyword.id}", headers: headers

      expect(response).to have_http_status(200)
    end
  end

  describe 'PUT /api/v1/filters/:id' do
    let_it_be(:filter)  { Fabricate(:custom_filter, account: user.account) }
    let_it_be(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    before do
      token.update!(scopes: 'write:filters')
      put "/api/v1/filters/#{keyword.id}", headers: headers, params: { phrase: 'updated' }
    end

    it 'updates the filter', :aggregate_failures do
      expect(response).to have_http_status(200)
      expect(keyword.reload.phrase).to eq 'updated'
    end
  end

  describe 'DELETE /api/v1/filters/:id' do
    let_it_be(:filter)  { Fabricate(:custom_filter, account: user.account) }
    let_it_be(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    before do
      token.update!(scopes: 'write:filters')
      delete "/api/v1/filters/#{keyword.id}", headers: headers
    end

    it 'removes the filter', :aggregate_failures do
      expect(response).to have_http_status(200)
      expect { keyword.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end