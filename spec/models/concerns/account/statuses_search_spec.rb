# frozen_string_literal: true

require 'rails_helper'

describe Account::StatusesSearch do
  let_it_be(:account) { Fabricate(:account) }

  before do
    allow(Chewy).to receive(:enabled?).and_return(true)
  end

  describe '#enqueue_update_public_statuses_index' do
    before do
      allow(account).to receive(:enqueue_add_to_public_statuses_index)
      allow(account).to receive(:enqueue_remove_from_public_statuses_index)
    end

    context 'when account is indexable' do
      before { account.update!(indexable: true) }

      it 'enqueues add_to_public_statuses_index and not to remove_from_public_statuses_index' do
        account.enqueue_update_public_statuses_index
        expect(account).to have_received(:enqueue_add_to_public_statuses_index).once
        expect(account).to_not have_received(:enqueue_remove_from_public_statuses_index)
      end
    end

    context 'when account is not indexable' do
      before { account.update!(indexable: false) }

      it 'enqueues remove_from_public_statuses_index and not to add_to_public_statuses_index' do
        account.enqueue_update_public_statuses_index
        expect(account).to have_received(:enqueue_remove_from_public_statuses_index).once
        expect(account).to_not have_received(:enqueue_add_to_public_statuses_index)
      end
    end
  end

  describe '#enqueue_add_to_public_statuses_index' do
    let(:worker) { AddToPublicStatusesIndexWorker }

    before do
      account.update!(indexable: true)
      allow(worker).to receive(:perform_async)
    end

    it 'enqueues AddToPublicStatusesIndexWorker' do
      account.enqueue_add_to_public_statuses_index
      expect(worker).to have_received(:perform_async).with(account.id).once
    end
  end

  describe '#enqueue_remove_from_public_statuses_index' do
    let(:worker) { RemoveFromPublicStatusesIndexWorker }

    before do
      account.update!(indexable: false)
      allow(worker).to receive(:perform_async)
    end

    it 'enqueues RemoveFromPublicStatusesIndexWorker' do
      account.enqueue_remove_from_public_statuses_index
      expect(worker).to have_received(:perform_async).with(account.id).once
    end
  end
end