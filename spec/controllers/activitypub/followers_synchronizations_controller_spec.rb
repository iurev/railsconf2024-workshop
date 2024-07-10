# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::FollowersSynchronizationsController, :account do
  let_it_be(:follower_example_com_user_a) { Fabricate(:account, domain: 'example.com', uri: 'https://example.com/users/a') }
  let_it_be(:follower_example_com_user_b) { Fabricate(:account, domain: 'example.com', uri: 'https://example.com/users/b') }
  let_it_be(:follower_foo_com_user_a) { Fabricate(:account, domain: 'foo.com', uri: 'https://foo.com/users/a') }
  let_it_be(:follower_example_com_instance_actor) { Fabricate(:account, username: 'instance-actor', domain: 'example.com', uri: 'https://example.com') }

  before_all do
    follower_example_com_user_a.follow!(account)
    follower_example_com_user_b.follow!(account)
    follower_foo_com_user_a.follow!(account)
    follower_example_com_instance_actor.follow!(account)
  end

  before do
    allow(controller).to receive(:signed_request_actor).and_return(remote_account)
  end

  describe 'GET #show' do
    context 'without signature' do
      let(:remote_account) { nil }

      before do
        get :show, params: { account_username: account.username }
      end

      it 'returns http not authorized' do
        expect(response).to have_http_status(401)
      end
    end

    context 'with signature from example.com' do
      subject(:response) { get :show, params: { account_username: account.username } }

      let(:body) { body_as_json }
      let(:remote_account) { Fabricate(:account, domain: 'example.com', uri: 'https://example.com/instance') }

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns application/activity+json' do
        expect(response.media_type).to eq 'application/activity+json'
      end

      it 'returns orderedItems with followers from example.com' do
        expect(body[:orderedItems]).to be_an Array
        expect(body[:orderedItems]).to contain_exactly(
          follower_example_com_instance_actor.uri,
          follower_example_com_user_a.uri,
          follower_example_com_user_b.uri
        )
      end

      it 'returns private Cache-Control header' do
        expect(response.headers['Cache-Control']).to eq 'max-age=0, private'
      end

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

        it 'returns http forbidden' do
          expect(response).to have_http_status(403)
        end
      end
    end
  end
end