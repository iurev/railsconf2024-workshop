# frozen_string_literal: true

require 'rails_helper'

describe 'Directories API' do
  let_it_be(:user)    { Fabricate(:user, confirmed_at: nil) }
  let_it_be(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:follows') }
  let_it_be(:headers) { { 'Authorization' => "Bearer #{token.token}" } }

  describe 'GET /api/v1/directories' do
    context 'with no params' do
      let_it_be(:local_unconfirmed_account) do
        Fabricate(:account, domain: nil, user: Fabricate(:user, confirmed_at: nil, approved: true), username: 'local_unconfirmed')
      end
      let_it_be(:local_unapproved_account) do
        Fabricate(:account, domain: nil, user: Fabricate(:user, confirmed_at: 10.days.ago), username: 'local_unapproved')
      end
      let_it_be(:local_undiscoverable_account) do
        Fabricate(:account, domain: nil, user: Fabricate(:user, confirmed_at: 10.days.ago, approved: true), discoverable: false, username: 'local_undiscoverable')
      end
      let_it_be(:excluded_from_timeline_account) do
        Fabricate(:account, domain: 'host.example', discoverable: true, username: 'remote_excluded_from_timeline')
      end
      let_it_be(:domain_blocked_account) do
        Fabricate(:account, domain: 'test.example', discoverable: true, username: 'remote_domain_blocked')
      end
      let_it_be(:local_discoverable_account) do
        Fabricate(:account, domain: nil, user: Fabricate(:user, confirmed_at: 10.days.ago, approved: true), discoverable: true, username: 'local_discoverable')
      end
      let_it_be(:eligible_remote_account) do
        Fabricate(:account, domain: 'host.example', discoverable: true, username: 'eligible_remote')
      end

      before_all do
        local_unconfirmed_account.create_account_stat!
        local_unapproved_account.create_account_stat!
        local_unapproved_account.user.update(approved: false)
        local_undiscoverable_account.create_account_stat!
        excluded_from_timeline_account.create_account_stat!
        domain_blocked_account.create_account_stat!
        local_discoverable_account.create_account_stat!
        eligible_remote_account.create_account_stat!
        Fabricate(:block, account: user.account, target_account: excluded_from_timeline_account)
        Fabricate(:account_domain_block, account: user.account, domain: 'test.example')
      end

      it 'returns the local discoverable account and the remote discoverable account' do
        get '/api/v1/directory', headers: headers

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(2)
        expect(body_as_json.pluck(:id)).to contain_exactly(eligible_remote_account.id.to_s, local_discoverable_account.id.to_s)
      end
    end

    context 'when asking for local accounts only' do
      let_it_be(:local_user) { Fabricate(:user, confirmed_at: 10.days.ago, approved: true) }
      let_it_be(:local_account) { Fabricate(:account, domain: nil, user: local_user) }
      let_it_be(:remote_account) { Fabricate(:account, domain: 'host.example') }

      before_all do
        local_account.create_account_stat!
        remote_account.create_account_stat!
      end

      it 'returns only the local accounts' do
        get '/api/v1/directory', headers: headers, params: { local: '1' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(1)
        expect(body_as_json.first[:id]).to include(local_account.id.to_s)
        expect(response.body).to_not include(remote_account.id.to_s)
      end
    end

    context 'when ordered by active' do
      let_it_be(:old_stat) { Fabricate(:account_stat, last_status_at: 1.day.ago) }
      let_it_be(:new_stat) { Fabricate(:account_stat, last_status_at: 1.minute.ago) }

      it 'returns accounts in order of most recent status activity' do
        get '/api/v1/directory', headers: headers, params: { order: 'active' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(2)
        expect(body_as_json.first[:id]).to include(new_stat.account_id.to_s)
        expect(body_as_json.second[:id]).to include(old_stat.account_id.to_s)
      end
    end

    context 'when ordered by new' do
      let_it_be(:account_old) { Fabricate(:account_stat).account }
      let_it_be(:account_new) { travel_to(10.seconds.from_now) { Fabricate(:account_stat).account } }

      it 'returns accounts in order of creation' do
        get '/api/v1/directory', headers: headers, params: { order: 'new' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq(2)
        expect(body_as_json.first[:id]).to include(account_new.id.to_s)
        expect(body_as_json.second[:id]).to include(account_old.id.to_s)
      end
    end
  end
end