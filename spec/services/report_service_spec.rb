# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportService do
  subject { described_class.new }

  let_it_be(:source_account) { Fabricate(:account) }
  let_it_be(:target_account) { Fabricate(:account) }
  let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com', protocol: :activitypub, inbox_url: 'http://example.com/inbox') }

  before_all do
    stub_request(:post, /http:\/\/(example\.com|foo\.com)\/inbox/).to_return(status: 200)
  end

  before do
    allow(ActivityPub::DeliveryWorker).to receive(:perform_async).and_return(true)
  end

  context 'with a local account' do
    it 'has a uri' do
      report = subject.call(source_account, target_account)
      expect(report.uri).to_not be_nil
    end
  end

  context 'with a remote account' do
    let(:forward) { false }

    context 'when forward is true' do
      let(:forward) { true }

      it 'sends ActivityPub payload when forward is true' do
        expect(ActivityPub::DeliveryWorker).to receive(:perform_async)
        subject.call(source_account, remote_account, forward: forward)
      end

      it 'has an uri' do
        report = subject.call(source_account, remote_account, forward: forward)
        expect(report.uri).to_not be_nil
      end

      context 'when reporting a reply on a different remote server' do
        let_it_be(:remote_thread_account) { Fabricate(:account, domain: 'foo.com', protocol: :activitypub, inbox_url: 'http://foo.com/inbox') }
        let_it_be(:reported_status) { Fabricate(:status, account: remote_account, thread: Fabricate(:status, account: remote_thread_account)) }

        context 'when forward_to_domains includes both the replied-to domain and the origin domain' do
          it 'sends ActivityPub payload to both the author of the replied-to post and the reported user' do
            expect(ActivityPub::DeliveryWorker).to receive(:perform_async).twice
            subject.call(source_account, remote_account, status_ids: [reported_status.id], forward: forward, forward_to_domains: [remote_account.domain, remote_thread_account.domain])
          end
        end

        context 'when forward_to_domains includes only the replied-to domain' do
          it 'sends ActivityPub payload only to the author of the replied-to post' do
            expect(ActivityPub::DeliveryWorker).to receive(:perform_async).once
            subject.call(source_account, remote_account, status_ids: [reported_status.id], forward: forward, forward_to_domains: [remote_thread_account.domain])
          end
        end

        context 'when forward_to_domains does not include the replied-to domain' do
          it 'does not send ActivityPub payload to the author of the replied-to post' do
            expect(ActivityPub::DeliveryWorker).to receive(:perform_async).once
            subject.call(source_account, remote_account, status_ids: [reported_status.id], forward: forward)
          end
        end
      end

      context 'when reporting a reply on the same remote server as the person being replied-to' do
        let_it_be(:remote_thread_account) { Fabricate(:account, domain: 'example.com', protocol: :activitypub, inbox_url: 'http://example.com/inbox') }
        let_it_be(:reported_status) { Fabricate(:status, account: remote_account, thread: Fabricate(:status, account: remote_thread_account)) }

        context 'when forward_to_domains includes both the replied-to domain and the origin domain' do
          it 'sends ActivityPub payload only once' do
            expect(ActivityPub::DeliveryWorker).to receive(:perform_async).once
            subject.call(source_account, remote_account, status_ids: [reported_status.id], forward: forward, forward_to_domains: [remote_account.domain])
          end
        end

        context 'when forward_to_domains does not include the replied-to domain' do
          it 'sends ActivityPub payload only once' do
            expect(ActivityPub::DeliveryWorker).to receive(:perform_async).once
            subject.call(source_account, remote_account, status_ids: [reported_status.id], forward: forward)
          end
        end
      end
    end

    context 'when forward is false' do
      it 'does not send anything' do
        expect(ActivityPub::DeliveryWorker).not_to receive(:perform_async)
        subject.call(source_account, remote_account, forward: forward)
      end
    end
  end

  context 'when the reported status is a DM' do
    subject do
      -> { described_class.new.call(source_account, target_account, status_ids: [status.id]) }
    end

    let_it_be(:status) { Fabricate(:status, account: target_account, visibility: :direct) }

    context 'when it is addressed to the reporter' do
      before do
        status.mentions.create(account: source_account)
      end

      it 'creates a report' do
        expect { subject.call }.to change { target_account.targeted_reports.count }.from(0).to(1)
      end

      it 'attaches the DM to the report' do
        subject.call
        expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[status.id]]
      end
    end

    context 'when it is not addressed to the reporter' do
      it 'errors out' do
        expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the reporter is remote' do
      let_it_be(:remote_source_account) { Fabricate(:account, domain: 'example.com', uri: 'https://example.com/users/1') }

      context 'when it is addressed to the reporter' do
        before do
          status.mentions.create(account: remote_source_account)
        end

        it 'creates a report' do
          expect { described_class.new.call(remote_source_account, target_account, status_ids: [status.id]) }.to change { target_account.targeted_reports.count }.from(0).to(1)
        end

        it 'attaches the DM to the report' do
          described_class.new.call(remote_source_account, target_account, status_ids: [status.id])
          expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[status.id]]
        end
      end

      context 'when it is not addressed to the reporter' do
        it 'does not add the DM to the report' do
          described_class.new.call(remote_source_account, target_account, status_ids: [status.id])
          expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[]]
        end
      end
    end
  end

  context 'when other reports already exist for the same target' do
    subject do
      -> { described_class.new.call(source_account, target_account) }
    end

    before do
      Fabricate(:report, target_account: target_account)
      source_account.user.settings['notification_emails.report'] = true
      source_account.user.save
    end

    it 'does not send an e-mail' do
      emails = capture_emails { subject.call }

      expect(emails).to be_empty
    end
  end
end