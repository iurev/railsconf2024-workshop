# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSettings::Namespace do
  subject { described_class.new(name) }

  let_it_be(:name) { :foo }

  describe '#setting' do
    before do
      subject.setting :bar, default: 'baz'
    end

    it 'adds setting to definitions' do
      expect(subject.definitions[:'foo.bar']).to have_attributes(name: :bar, namespace: :foo, default_value: 'baz')
    end
  end

  describe '#definitions' do
    it 'returns a hash' do
      expect(subject.definitions).to be_a Hash
    end
  end
end