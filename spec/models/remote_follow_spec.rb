# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteFollow do
  before do
    stub_request(:get, 'https://quitter.no/.well-known/webfinger?resource=acct:gargron@quitter.no').to_return(request_fixture('webfinger.txt'))
  end

  let_it_be(:remote_follow_with_acct) { described_class.new(acct: 'gargron@quitter.no') }
  let_it_be(:remote_follow_without_acct) { described_class.new }

  describe '.initialize' do
    context 'when attrs with acct' do
      subject { remote_follow_with_acct.acct }

      it 'returns acct' do
        expect(subject).to eq 'gargron@quitter.no'
      end
    end

    context 'when attrs without acct' do
      subject { remote_follow_without_acct.acct }

      it do
        expect(subject).to be_nil
      end
    end
  end

  describe '#valid?' do
    context 'when attrs with acct' do
      subject { remote_follow_with_acct.valid? }

      it do
        expect(subject).to be true
      end
    end

    context 'when attrs without acct' do
      subject { remote_follow_without_acct.valid? }

      it do
        expect(subject).to be false
      end
    end
  end

  describe '#subscribe_address_for' do
    subject { remote_follow_with_acct.subscribe_address_for(account) }

    let(:account) { Fabricate(:account, username: 'alice') }

    before do
      remote_follow_with_acct.valid?
    end

    it 'returns subscribe address' do
      expect(subject).to eq 'https://quitter.no/main/ostatussub?profile=https%3A%2F%2Fcb6e6126.ngrok.io%2Fusers%2Falice'
    end
  end
end