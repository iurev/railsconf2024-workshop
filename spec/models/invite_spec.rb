# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invite do
  let_it_be(:invite) { Fabricate(:invite, max_uses: nil, expires_at: nil) }

  describe '#valid_for_use?' do
    it 'returns true when there are no limitations' do
      expect(invite.valid_for_use?).to be true
    end

    it 'returns true when not expired' do
      invite.update!(expires_at: 1.hour.from_now)
      expect(invite.valid_for_use?).to be true
    end

    it 'returns false when expired' do
      invite.update!(expires_at: 1.hour.ago)
      expect(invite.valid_for_use?).to be false
    end

    it 'returns true when uses still available' do
      invite.update!(max_uses: 250, uses: 249)
      expect(invite.valid_for_use?).to be true
    end

    it 'returns false when maximum uses reached' do
      invite.update!(max_uses: 250, uses: 250)
      expect(invite.valid_for_use?).to be false
    end

    it 'returns false when invite creator has been disabled' do
      invite.user.account.suspend!
      expect(invite.valid_for_use?).to be false
    end
  end
end