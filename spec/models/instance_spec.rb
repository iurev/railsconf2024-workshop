# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Instance do
  describe 'Scopes' do
    before { described_class.refresh }

    describe '#searchable' do
      let_it_be(:expected_domain) { 'host.example' }
      let_it_be(:blocked_domain) { 'other.example' }
      let_it_be(:expected_account) { Fabricate :account, domain: expected_domain }
      let_it_be(:blocked_account) { Fabricate :account, domain: blocked_domain }
      let_it_be(:domain_block) { Fabricate :domain_block, domain: blocked_domain }

      it 'returns records not domain blocked' do
        results = described_class.searchable.pluck(:domain)

        expect(results)
          .to include(expected_domain)
          .and not_include(blocked_domain)
      end
    end

    describe '#matches_domain' do
      let_it_be(:host_domain) { 'host.example.com' }
      let_it_be(:host_under_domain) { 'host_under.example.com' }
      let_it_be(:other_domain) { 'other.example' }
      let_it_be(:host_account) { Fabricate :account, domain: host_domain }
      let_it_be(:host_under_account) { Fabricate :account, domain: host_under_domain }
      let_it_be(:other_account) { Fabricate :account, domain: other_domain }

      it 'returns matching records' do
        expect(described_class.matches_domain('host.exa').pluck(:domain))
          .to include(host_domain)
          .and not_include(other_domain)

        expect(described_class.matches_domain('ple.com').pluck(:domain))
          .to include(host_domain)
          .and not_include(other_domain)

        expect(described_class.matches_domain('example').pluck(:domain))
          .to include(host_domain)
          .and include(other_domain)

        expect(described_class.matches_domain('host_').pluck(:domain)) # Preserve SQL wildcards
          .to include(host_domain)
          .and include(host_under_domain)
          .and not_include(other_domain)
      end
    end

    describe '#by_domain_and_subdomains' do
      let_it_be(:exact_match_domain) { 'example.com' }
      let_it_be(:subdomain_domain) { 'foo.example.com' }
      let_it_be(:partial_domain) { 'grexample.com' }
      let_it_be(:exact_match_account) { Fabricate(:account, domain: exact_match_domain) }
      let_it_be(:subdomain_account) { Fabricate(:account, domain: subdomain_domain) }
      let_it_be(:partial_account) { Fabricate(:account, domain: partial_domain) }

      it 'returns matching instances' do
        results = described_class.by_domain_and_subdomains('example.com').pluck(:domain)

        expect(results)
          .to include(exact_match_domain)
          .and include(subdomain_domain)
          .and not_include(partial_domain)
      end
    end

    describe '#with_domain_follows' do
      let_it_be(:example_domain) { 'example.host' }
      let_it_be(:other_domain) { 'other.host' }
      let_it_be(:none_domain) { 'none.host' }
      let_it_be(:example_account) { Fabricate(:account, domain: example_domain) }
      let_it_be(:other_account) { Fabricate(:account, domain: other_domain) }
      let_it_be(:none_account) { Fabricate(:account, domain: none_domain) }
      let_it_be(:example_follow) { Fabricate :follow, account: example_account }
      let_it_be(:other_follow) { Fabricate :follow, target_account: other_account }

      it 'returns instances with domain accounts that have follows' do
        results = described_class.with_domain_follows(['example.host', 'other.host', 'none.host']).pluck(:domain)

        expect(results)
          .to include(example_domain)
          .and include(other_domain)
          .and not_include(none_domain)
      end
    end
  end
end