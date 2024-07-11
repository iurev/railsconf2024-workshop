# frozen_string_literal: true

require 'rails_helper'

describe Admin::DisputesHelper do
  describe 'strike_action_label' do
    let_it_be(:adam) { Account.new(username: 'Adam') }
    let_it_be(:becky) { Account.new(username: 'Becky') }
    let_it_be(:strike) { AccountWarning.new(account: adam, action: :suspend) }

    it 'returns html describing the appeal' do
      appeal = Appeal.new(strike: strike, account: becky)

      expected = <<~OUTPUT.strip
        <span class="username">Adam</span> suspended <span class="target">Becky</span>'s account
      OUTPUT
      result = helper.strike_action_label(appeal)

      expect(result).to eq(expected)
    end
  end
end