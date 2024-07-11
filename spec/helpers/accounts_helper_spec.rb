# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountsHelper do
  def set_not_embedded_view
    params[:controller] = "not_#{StatusesHelper::EMBEDDED_CONTROLLER}"
    params[:action] = "not_#{StatusesHelper::EMBEDDED_ACTION}"
  end

  def set_embedded_view
    params[:controller] = StatusesHelper::EMBEDDED_CONTROLLER
    params[:action] = StatusesHelper::EMBEDDED_ACTION
  end

  describe '#display_name' do
    let_it_be(:account_with_display_name) { Account.new(display_name: 'Display', username: 'Username') }
    let_it_be(:account_without_display_name) { Account.new(display_name: nil, username: 'Username') }

    it 'uses the display name when it exists' do
      expect(helper.display_name(account_with_display_name)).to eq 'Display'
    end

    it 'uses the username when display name is nil' do
      expect(helper.display_name(account_without_display_name)).to eq 'Username'
    end
  end

  describe '#acct' do
    let_it_be(:local_account) { Account.new(domain: nil, username: 'user') }
    let_it_be(:foreign_account) { Account.new(domain: 'foreign_server.com', username: 'user') }

    before do
      allow(Rails.configuration.x).to receive(:local_domain).and_return('local_domain')
    end

    it 'is fully qualified for embedded local accounts' do
      set_embedded_view
      expect(helper.acct(local_account)).to eq '@user@local_domain'
    end

    it 'is fully qualified for embedded foreign accounts' do
      set_embedded_view
      expect(helper.acct(foreign_account)).to eq '@user@foreign_server.com'
    end

    it 'is fully qualified for non embedded foreign accounts' do
      set_not_embedded_view
      expect(helper.acct(foreign_account)).to eq '@user@foreign_server.com'
    end

    it 'is fully qualified for non embedded local accounts' do
      set_not_embedded_view
      expect(helper.acct(local_account)).to eq '@user@local_domain'
    end
  end
end