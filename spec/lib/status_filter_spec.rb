# frozen_string_literal: true

require 'rails_helper'

describe StatusFilter do
  describe '#filtered?' do
    let_it_be(:status) { Fabricate(:status) }
    let_it_be(:account) { Fabricate(:account) }

    context 'without an account' do
      subject(:filter) { described_class.new(status, nil) }

      context 'when there are no connections' do
        it { is_expected.to_not be_filtered }
      end

      context 'when status account is silenced' do
        before_all do
          status.account.silence!
        end

        it { is_expected.to be_filtered }

        after_all do
          status.account.unsilence!
        end
      end

      context 'when status policy does not allow show' do
        it 'filters the status' do
          policy = instance_double(StatusPolicy, show?: false)
          allow(StatusPolicy).to receive(:new).and_return(policy)

          expect(filter).to be_filtered
        end
      end
    end

    context 'with real account' do
      subject(:filter) { described_class.new(status, account) }

      context 'when there are no connections' do
        it { is_expected.to_not be_filtered }
      end

      context 'when status account is blocked' do
        before_all do
          Fabricate(:block, account: account, target_account: status.account)
        end

        it { is_expected.to be_filtered }
      end

      context 'when status account domain is blocked' do
        before_all do
          status.account.update(domain: 'example.com')
          Fabricate(:account_domain_block, account: account, domain: status.account_domain)
        end

        it { is_expected.to be_filtered }

        after_all do
          status.account.update(domain: nil)
        end
      end

      context 'when status account is muted' do
        before_all do
          Fabricate(:mute, account: account, target_account: status.account)
        end

        it { is_expected.to be_filtered }
      end

      context 'when status account is silenced' do
        before_all do
          status.account.silence!
        end

        it { is_expected.to be_filtered }

        after_all do
          status.account.unsilence!
        end
      end

      context 'when status policy does not allow show' do
        it 'filters the status' do
          policy = instance_double(StatusPolicy, show?: false)
          allow(StatusPolicy).to receive(:new).and_return(policy)

          expect(filter).to be_filtered
        end
      end
    end
  end
end