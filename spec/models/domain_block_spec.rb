# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DomainBlock do
  let_it_be(:suspend_block) { Fabricate(:domain_block, domain: 'suspended.com', severity: :suspend) }
  let_it_be(:silence_block) { Fabricate(:domain_block, domain: 'silenced.com', severity: :silence) }

  describe 'validations' do
    it 'is invalid without a domain' do
      domain_block = Fabricate.build(:domain_block, domain: nil)
      domain_block.valid?
      expect(domain_block).to model_have_error_on_field(:domain)
    end

    it 'is invalid if the same normalized domain already exists' do
      Fabricate(:domain_block, domain: 'にゃん')
      domain_block_with_normalized_value = Fabricate.build(:domain_block, domain: 'xn--r9j5b5b')
      domain_block_with_normalized_value.valid?
      expect(domain_block_with_normalized_value).to model_have_error_on_field(:domain)
    end
  end

  describe '.blocked?' do
    it 'returns true if the domain is suspended' do
      expect(described_class.blocked?('suspended.com')).to be true
    end

    it 'returns false even if the domain is silenced' do
      expect(described_class.blocked?('silenced.com')).to be false
    end

    it 'returns false if the domain is not suspended nor silenced' do
      expect(described_class.blocked?('example.com')).to be false
    end
  end

  describe '.rule_for' do
    let_it_be(:subdomain_block) { Fabricate(:domain_block, domain: 'sub.example.com') }
    let_it_be(:tld_block) { Fabricate(:domain_block, domain: 'google') }

    it 'returns rule matching a blocked domain' do
      expect(described_class.rule_for('suspended.com')).to eq suspend_block
    end

    it 'returns a rule matching a subdomain of a blocked domain' do
      expect(described_class.rule_for('sub.suspended.com')).to eq suspend_block
    end

    it 'returns a rule matching a blocked subdomain' do
      expect(described_class.rule_for('sub.example.com')).to eq subdomain_block
    end

    it 'returns a rule matching a blocked TLD' do
      expect(described_class.rule_for('google')).to eq tld_block
    end

    it 'returns a rule matching a subdomain of a blocked TLD' do
      expect(described_class.rule_for('maps.google')).to eq tld_block
    end
  end

  describe '#stricter_than?' do
    let(:noop) { described_class.new(domain: 'noop.com', severity: :noop) }

    it 'returns true if the new block has suspend severity while the old has lower severity' do
      expect(suspend_block.stricter_than?(silence_block)).to be true
      expect(suspend_block.stricter_than?(noop)).to be true
    end

    it 'returns false if the new block has lower severity than the old one' do
      expect(silence_block.stricter_than?(suspend_block)).to be false
      expect(noop.stricter_than?(suspend_block)).to be false
      expect(noop.stricter_than?(silence_block)).to be false
    end

    it 'returns false if the new block is less strict regarding reports' do
      older = described_class.new(domain: 'older.com', severity: :silence, reject_reports: true)
      newer = described_class.new(domain: 'newer.com', severity: :silence, reject_reports: false)
      expect(newer.stricter_than?(older)).to be false
    end

    it 'returns false if the new block is less strict regarding media' do
      older = described_class.new(domain: 'older.com', severity: :silence, reject_media: true)
      newer = described_class.new(domain: 'newer.com', severity: :silence, reject_media: false)
      expect(newer.stricter_than?(older)).to be false
    end
  end

  describe '#public_domain' do
    context 'with a domain block that is obfuscated' do
      let(:domain_block) { Fabricate(:domain_block, domain: 'hostname.example.com', obfuscate: true) }

      it 'garbles the domain' do
        expect(domain_block.public_domain).to eq 'hostna**.******e.com'
      end
    end

    context 'with a domain block that is not obfuscated' do
      let(:domain_block) { Fabricate(:domain_block, domain: 'example.com', obfuscate: false) }

      it 'returns the domain value' do
        expect(domain_block.public_domain).to eq 'example.com'
      end
    end
  end
end