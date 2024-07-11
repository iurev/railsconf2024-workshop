# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SeveredRelationship do
  let_it_be(:local_account)  { Fabricate(:account) }
  let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com') }
  let_it_be(:event)          { Fabricate(:relationship_severance_event) }

  describe '#account' do
    context 'when the local account is the follower' do
      let(:severed_relationship) { Fabricate(:severed_relationship, relationship_severance_event: event, local_account: local_account, remote_account: remote_account, direction: :active) }

      it 'returns the local account' do
        expect(severed_relationship.account).to eq local_account
      end
    end

    context 'when the local account is being followed' do
      let(:severed_relationship) { Fabricate(:severed_relationship, relationship_severance_event: event, local_account: local_account, remote_account: remote_account, direction: :passive) }

      it 'returns the remote account' do
        expect(severed_relationship.account).to eq remote_account
      end
    end
  end

  describe '#target_account' do
    context 'when the local account is the follower' do
      let(:severed_relationship) { Fabricate(:severed_relationship, relationship_severance_event: event, local_account: local_account, remote_account: remote_account, direction: :active) }

      it 'returns the remote account' do
        expect(severed_relationship.target_account).to eq remote_account
      end
    end

    context 'when the local account is being followed' do
      let(:severed_relationship) { Fabricate(:severed_relationship, relationship_severance_event: event, local_account: local_account, remote_account: remote_account, direction: :passive) }

      it 'returns the local account' do
        expect(severed_relationship.target_account).to eq local_account
      end
    end
  end
end