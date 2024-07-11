# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SeveredRelationship do
  let_it_be(:local_account)  { Fabricate(:account) }
  let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com') }
  let_it_be(:event)          { Fabricate(:relationship_severance_event) }
  let_it_be(:active_severed_relationship) { Fabricate(:severed_relationship, relationship_severance_event: event, local_account: local_account, remote_account: remote_account, direction: :active) }
  let_it_be(:passive_severed_relationship) { Fabricate(:severed_relationship, relationship_severance_event: event, local_account: local_account, remote_account: remote_account, direction: :passive) }

  describe '#account' do
    context 'when the local account is the follower' do
      it 'returns the local account' do
        expect(active_severed_relationship.account).to eq local_account
      end
    end

    context 'when the local account is being followed' do
      it 'returns the remote account' do
        expect(passive_severed_relationship.account).to eq remote_account
      end
    end
  end

  describe '#target_account' do
    context 'when the local account is the follower' do
      it 'returns the remote account' do
        expect(active_severed_relationship.target_account).to eq remote_account
      end
    end

    context 'when the local account is being followed' do
      it 'returns the local account' do
        expect(passive_severed_relationship.target_account).to eq local_account
      end
    end
  end
end