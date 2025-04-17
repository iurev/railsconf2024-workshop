# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountConversation do
  let_it_be(:alice) { Fabricate(:account, username: 'alice') }
  let_it_be(:bob)   { Fabricate(:account, username: 'bob') }
  let_it_be(:mark)  { Fabricate(:account, username: 'mark') }

  describe '.add_status' do
    let_it_be(:direct_status) { Fabricate(:status, account: alice, visibility: :direct) }

    it 'creates new record when no others exist' do
      direct_status.mentions.create(account: bob)

      conversation = described_class.add_status(alice, direct_status)

      expect(conversation.participant_accounts).to include(bob)
      expect(conversation.last_status).to eq direct_status
      expect(conversation.status_ids).to eq [direct_status.id]
    end

    it 'appends to old record when there is a match' do
      conversation = described_class.create!(account: alice, conversation: direct_status.conversation, participant_account_ids: [bob.id], status_ids: [direct_status.id])

      status = Fabricate(:status, account: bob, visibility: :direct, thread: direct_status)
      status.mentions.create(account: alice)

      new_conversation = described_class.add_status(alice, status)

      expect(new_conversation.id).to eq conversation.id
      expect(new_conversation.participant_accounts).to include(bob)
      expect(new_conversation.last_status).to eq status
      expect(new_conversation.status_ids).to eq [direct_status.id, status.id]
    end

    it 'creates new record when new participants are added' do
      conversation = described_class.create!(account: alice, conversation: direct_status.conversation, participant_account_ids: [bob.id], status_ids: [direct_status.id])

      status = Fabricate(:status, account: bob, visibility: :direct, thread: direct_status)
      status.mentions.create(account: alice)
      status.mentions.create(account: mark)

      new_conversation = described_class.add_status(alice, status)

      expect(new_conversation.id).to_not eq conversation.id
      expect(new_conversation.participant_accounts).to include(bob, mark)
      expect(new_conversation.last_status).to eq status
      expect(new_conversation.status_ids).to eq [status.id]
    end
  end

  describe '.remove_status' do
    let_it_be(:direct_status) { Fabricate(:status, account: alice, visibility: :direct) }

    it 'updates last status to a previous value' do
      status       = Fabricate(:status, account: alice, visibility: :direct)
      conversation = described_class.create!(account: alice, conversation: direct_status.conversation, participant_account_ids: [bob.id], status_ids: [status.id, direct_status.id])
      direct_status.mentions.create(account: bob)
      direct_status.destroy!
      conversation.reload
      expect(conversation.last_status).to eq status
      expect(conversation.status_ids).to eq [status.id]
    end

    it 'removes the record if no other statuses are referenced' do
      conversation = described_class.create!(account: alice, conversation: direct_status.conversation, participant_account_ids: [bob.id], status_ids: [direct_status.id])
      direct_status.mentions.create(account: bob)
      direct_status.destroy!
      expect(described_class.where(id: conversation.id).count).to eq 0
    end
  end
end