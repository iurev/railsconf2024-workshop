# frozen_string_literal: true

require 'rails_helper'

describe AccountWarningPreset do
  describe 'alphabetical' do
    let_it_be(:first) { Fabricate(:account_warning_preset, title: 'aaa', text: 'aaa') }
    let_it_be(:second) { Fabricate(:account_warning_preset, title: 'bbb', text: 'aaa') }
    let_it_be(:third) { Fabricate(:account_warning_preset, title: 'bbb', text: 'bbb') }

    it 'returns records in order of title and text' do
      results = described_class.alphabetic

      expect(results).to eq([first, second, third])
    end
  end
end