# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountSuggestions::Source do
  describe '#base_account_scope' do
    subject { FakeSource.new }

    before do
      stub_const 'FakeSource', fake_source_class
    end

    context 'with follows and follow requests' do
      let_it_be(:account) { Fabricate(:account, discoverable: true) }
      let_it_be(:account_domain_blocked_account) { Fabricate(:account, domain: 'blocked.host', discoverable: true) }
      let_it_be(:blocked_account) { Fabricate(:account, discoverable: true) }
      let_it_be(:eligible_account) { Fabricate(:account, discoverable: true) }
      let_it_be(:follow_recommendation_muted_account) { Fabricate(:account, discoverable: true) }
      let_it_be(:follow_requested_account) { Fabricate(:account, discoverable: true) }
      let_it_be(:following_account) { Fabricate(:account, discoverable: true) }
      let_it_be(:moved_account) { Fabricate(:account, moved_to_account: Fabricate(:account), discoverable: true) }
      let_it_be(:silenced_account) { Fabricate(:account, silenced: true, discoverable: true) }
      let_it_be(:undiscoverable_account) { Fabricate(:account, discoverable: false) }

      before_all do
        Fabricate :account_domain_block, account: account, domain: account_domain_blocked_account.domain
        Fabricate :block, account: account, target_account: blocked_account
        Fabricate :follow_recommendation_mute, account: account, target_account: follow_recommendation_muted_account
        Fabricate :follow_request, account: account, target_account: follow_requested_account
        Fabricate :follow, account: account, target_account: following_account
      end

      it 'returns eligible accounts' do
        results = subject.get(account)

        expect(results)
          .to include(eligible_account)
          .and not_include(account_domain_blocked_account)
          .and not_include(account)
          .and not_include(blocked_account)
          .and not_include(follow_recommendation_muted_account)
          .and not_include(follow_requested_account)
          .and not_include(following_account)
          .and not_include(moved_account)
          .and not_include(silenced_account)
          .and not_include(undiscoverable_account)
      end
    end
  end

  private

  def fake_source_class
    Class.new described_class do
      def get(account, limit: 10)
        base_account_scope(account)
          .limit(limit)
      end
    end
  end
end