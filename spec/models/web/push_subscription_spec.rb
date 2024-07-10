# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Web::PushSubscription do
  subject { described_class.new(data: data) }

  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:data) do
    {
      policy: 'all',
      alerts: {
        mention: true,
        reblog: false,
        follow: true,
        follow_request: false,
        favourite: true,
      },
    }
  end
  let_it_be(:notification, reload: true) { Fabricate(:notification, account: account, type: :mention) }

  describe '#pushable?' do
    %i(mention reblog follow follow_request favourite).each do |type|
      context "when notification is a #{type}" do
        before { notification.update!(type: type) }

        it 'returns boolean corresponding to alert setting' do
          expect(subject.pushable?(notification)).to eq data[:alerts][type]
        end
      end
    end

    context 'when policy is all' do
      it 'returns true' do
        expect(subject.pushable?(notification)).to be true
      end
    end

    context 'when policy is none' do
      before { data[:policy] = 'none' }

      it 'returns false' do
        expect(subject.pushable?(notification)).to be false
      end
    end

    context 'when policy is followed' do
      before { data[:policy] = 'followed' }

      context 'when notification is from someone you follow' do
        before do
          account.follow!(notification.from_account)
        end

        it 'returns true' do
          expect(subject.pushable?(notification)).to be true
        end
      end

      context 'when notification is not from someone you follow' do
        it 'returns false' do
          expect(subject.pushable?(notification)).to be false
        end
      end
    end

    context 'when policy is follower' do
      before { data[:policy] = 'follower' }

      context 'when notification is from someone who follows you' do
        before do
          notification.from_account.follow!(account)
        end

        it 'returns true' do
          expect(subject.pushable?(notification)).to be true
        end
      end

      context 'when notification is not from someone who follows you' do
        it 'returns false' do
          expect(subject.pushable?(notification)).to be false
        end
      end
    end
  end
end