# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::InboxesController, :account do
  let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com', protocol: :activitypub) }
  let(:signed_request_actor) { nil }

  before do
    allow(controller).to receive(:signed_request_actor).and_return(signed_request_actor)
  end

  describe 'POST #create' do
    context 'with signature' do
      let(:signed_request_actor) { remote_account }

      before do
        post :create, body: '{}'
      end

      it 'returns http accepted' do
        expect(response).to have_http_status(202)
      end

      context 'with a specific account' do
        subject(:response) { post :create, params: { account_username: account.username }, body: '{}' }

        context 'when account is permanently suspended' do
          before do
            account.suspend!
            account.deletion_request.destroy
          end

          it 'returns http gone' do
            expect(response).to have_http_status(410)
          end
        end

        context 'when account is temporarily suspended' do
          before do
            account.suspend!
          end

          it 'returns http accepted' do
            expect(response).to have_http_status(202)
          end
        end
      end
    end

    context 'with Collection-Synchronization header' do
      let(:signed_request_actor) { remote_account }
      let(:synchronization_collection) { remote_account.followers_url }
      let(:synchronization_url)        { 'https://example.com/followers-for-domain' }
      let(:synchronization_hash)       { 'somehash' }
      let(:synchronization_header)     { "collectionId=\"#{synchronization_collection}\", digest=\"#{synchronization_hash}\", url=\"#{synchronization_url}\"" }

      before do
        allow(ActivityPub::FollowersSynchronizationWorker).to receive(:perform_async).and_return(nil)
        allow(remote_account).to receive(:local_followers_hash).and_return('somehash')
        remote_account.update(followers_url: 'https://example.com/followers', uri: 'https://example.com/actor')

        request.headers['Collection-Synchronization'] = synchronization_header
        post :create, body: '{}'
      end

      context 'with mismatching target collection' do
        let(:synchronization_collection) { 'https://example.com/followers2' }

        it 'does not start a synchronization job' do
          expect(ActivityPub::FollowersSynchronizationWorker).to_not have_received(:perform_async)
        end
      end

      context 'with mismatching domain in partial collection attribute' do
        let(:synchronization_url) { 'https://example.org/followers' }

        it 'does not start a synchronization job' do
          expect(ActivityPub::FollowersSynchronizationWorker).to_not have_received(:perform_async)
        end
      end

      context 'with matching digest' do
        it 'does not start a synchronization job' do
          expect(ActivityPub::FollowersSynchronizationWorker).to_not have_received(:perform_async)
        end
      end

      context 'with mismatching digest' do
        let(:synchronization_hash) { 'wronghash' }

        it 'starts a synchronization job' do
          expect(ActivityPub::FollowersSynchronizationWorker).to have_received(:perform_async)
        end
      end

      it 'returns http accepted' do
        expect(response).to have_http_status(202)
      end
    end

    context 'without signature' do
      before do
        post :create, body: '{}'
      end

      it 'returns http not authorized' do
        expect(response).to have_http_status(401)
      end
    end
  end
end