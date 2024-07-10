# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessMentionsService do
  subject { described_class.new }

  let_it_be(:account) { Fabricate(:account, username: 'alice') }

  context 'when mentions contain blocked accounts' do
    let_it_be(:non_blocked_account)          { Fabricate(:account) }
    let_it_be(:individually_blocked_account) { Fabricate(:account) }
    let_it_be(:domain_blocked_account)       { Fabricate(:account, domain: 'evil.com') }
    let_it_be(:status) { Fabricate(:status, account: account, text: "Hello @#{non_blocked_account.acct} @#{individually_blocked_account.acct} @#{domain_blocked_account.acct}", visibility: :public) }

    before_all do
      account.block!(individually_blocked_account)
      account.domain_blocks.create!(domain: domain_blocked_account.domain)
    end

    before do
      subject.call(status)
    end

    it 'creates a mention to the non-blocked account' do
      expect(non_blocked_account.mentions.where(status: status).count).to eq 1
    end

    it 'does not create a mention to the individually blocked account' do
      expect(individually_blocked_account.mentions.where(status: status).count).to eq 0
    end

    it 'does not create a mention to the domain-blocked account' do
      expect(domain_blocked_account.mentions.where(status: status).count).to eq 0
    end
  end

  context 'with resolving a mention to a remote account' do
    let_it_be(:remote_user) { Fabricate(:account, username: 'remote_user', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox') }
    let(:status) { Fabricate(:status, account: account, text: "Hello @#{remote_user.acct}", visibility: :public) }

    context 'with ActivityPub' do
      context 'with a valid remote user' do
        before do
          subject.call(status)
        end

        it 'creates a mention' do
          expect(remote_user.mentions.where(status: status).count).to eq 1
        end
      end

      context 'when mentioning a user several times when not saving records' do
        let(:status) { Fabricate(:status, account: account, text: "Hello @#{remote_user.acct} @#{remote_user.acct} @#{remote_user.acct}", visibility: :public) }

        before do
          subject.call(status, save_records: false)
        end

        it 'creates exactly one mention' do
          expect(status.mentions.size).to eq 1
        end
      end

      context 'with an IDN domain' do
        let_it_be(:idn_remote_user) { Fabricate(:account, username: 'sneak', protocol: :activitypub, domain: 'xn--hresiar-mxa.ch', inbox_url: 'http://example.com/inbox') }
        let(:idn_status) { Fabricate(:status, account: account, text: 'Hello @sneak@hæresiar.ch') }

        before do
          subject.call(idn_status)
        end

        it 'creates a mention' do
          expect(idn_remote_user.mentions.where(status: idn_status).count).to eq 1
        end
      end

      context 'with an IDN TLD' do
        let_it_be(:idn_tld_remote_user) { Fabricate(:account, username: 'foo', protocol: :activitypub, domain: 'xn--y9a3aq.xn--y9a3aq', inbox_url: 'http://example.com/inbox') }
        let(:idn_tld_status) { Fabricate(:status, account: account, text: 'Hello @foo@հայ.հայ') }

        before do
          subject.call(idn_tld_status)
        end

        it 'creates a mention' do
          expect(idn_tld_remote_user.mentions.where(status: idn_tld_status).count).to eq 1
        end
      end
    end

    context 'with a Temporarily-unreachable ActivityPub user' do
      let_it_be(:unreachable_remote_user) { Fabricate(:account, username: 'remote_user', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox', last_webfingered_at: nil) }
      let(:unreachable_status) { Fabricate(:status, account: account, text: "Hello @#{unreachable_remote_user.acct}", visibility: :public) }

      before do
        stub_request(:get, 'https://example.com/.well-known/host-meta').to_return(status: 404)
        stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct:remote_user@example.com').to_return(status: 500)
        subject.call(unreachable_status)
      end

      it 'creates a mention' do
        expect(unreachable_remote_user.mentions.where(status: unreachable_status).count).to eq 1
      end
    end
  end
end