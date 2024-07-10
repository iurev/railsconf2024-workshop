# frozen_string_literal: true

require 'rails_helper'

describe PollExpirationNotifyWorker do
  let_it_be(:worker) { described_class.new }
  let_it_be(:account) { Fabricate(:account, domain: nil) }
  let_it_be(:status) { Fabricate(:status, account: account) }
  let_it_be(:poll) { Fabricate(:poll, status: status, account: account) }
  let_it_be(:poll_vote) { Fabricate(:poll_vote, poll: poll) }

  before_all { Sidekiq::Testing.fake! }

  describe '#perform' do
    it 'runs without error for missing record' do
      expect { worker.perform(nil) }.to_not raise_error
    end

    context 'when poll is not expired' do
      it 'requeues job' do
        worker.perform(poll.id)
        expect(described_class.sidekiq_options_hash['lock']).to be :until_executing
        expect(described_class).to have_enqueued_sidekiq_job(poll.id).at(poll.expires_at + 5.minutes)
      end
    end

    context 'when poll is expired' do
      before do
        travel_to poll.expires_at + 5.minutes
        worker.perform(poll.id)
      end

      context 'when poll is local' do
        it 'notifies voters' do
          expect(ActivityPub::DistributePollUpdateWorker).to have_enqueued_sidekiq_job(poll.status.id)
        end

        it 'notifies owner' do
          expect(LocalNotificationWorker).to have_enqueued_sidekiq_job(poll.account.id, poll.id, 'Poll', 'poll')
        end

        it 'notifies local voters' do
          expect(LocalNotificationWorker).to have_enqueued_sidekiq_job(poll_vote.account.id, poll.id, 'Poll', 'poll')
        end
      end

      context 'when poll is remote' do
        let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com') }
        let_it_be(:remote_status) { Fabricate(:status, account: remote_account) }
        let_it_be(:remote_poll) { Fabricate(:poll, status: remote_status, account: remote_account) }

        before do
          worker.perform(remote_poll.id)
        end

        it 'does not notify remote voters' do
          expect(ActivityPub::DistributePollUpdateWorker).to_not have_enqueued_sidekiq_job(remote_poll.status.id)
        end

        it 'does not notify owner' do
          expect(LocalNotificationWorker).to_not have_enqueued_sidekiq_job(remote_poll.account.id, remote_poll.id, 'Poll', 'poll')
        end

        it 'notifies local voters' do
          local_vote = Fabricate(:poll_vote, poll: remote_poll)
          expect(LocalNotificationWorker).to have_enqueued_sidekiq_job(local_vote.account.id, remote_poll.id, 'Poll', 'poll')
        end
      end
    end
  end
end