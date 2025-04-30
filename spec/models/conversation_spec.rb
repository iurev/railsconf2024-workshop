# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversation do
  let_it_be(:conversation) { Fabricate(:conversation) }

  describe '#local?' do
    it 'returns true when URI is nil' do
      expect(conversation.local?).to be true
    end

    it 'returns false when URI is not nil' do
      conversation.update(uri: 'abc')
      expect(conversation.local?).to be false
    end
  end
end