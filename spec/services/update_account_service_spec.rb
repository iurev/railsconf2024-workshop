# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateAccountService do
  subject { described_class.new }

  describe 'switching form locked to unlocked accounts' do
    let_it_be(:account) { Fabricate(:account, locked: true) }
    let_it_be(:alice)   { Fabricate(:account) }
    let_it_be(:bob)     { Fabricate(:account) }
    let_it_be(:eve)     { Fabricate(:account) }

    before do
      bob.touch(:silenced_at)
      account.mute!(eve)

      FollowService.new.call(alice, account)
      FollowService.new.call(bob, account)
      FollowService.new.call(eve, account)

      subject.call(account, { locked: false })
    end

    it 'auto-accepts pending follow requests', sidekiq: :inline do
      expect(alice.following?(account)).to be true
      expect(alice.requested?(account)).to be false
    end

    it 'does not auto-accept pending follow requests from silenced users' do
      expect(bob.following?(account)).to be false
      expect(bob.requested?(account)).to be true
    end

    it 'auto-accepts pending follow requests from muted users so as to not leak mute', sidekiq: :inline do
      expect(eve.following?(account)).to be true
      expect(eve.requested?(account)).to be false
    end
  end
end