# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomFilterKeyword do
  describe '#to_regex' do
    context 'when whole_word is true' do
      let_it_be(:keyword_whole_word) { described_class.new(whole_word: true, keyword: 'test') }
      let_it_be(:keyword_end_non_word) { described_class.new(whole_word: true, keyword: 'test#') }
      let_it_be(:keyword_start_non_word) { described_class.new(whole_word: true, keyword: '#test') }

      it 'builds a regex with boundaries and the keyword' do
        expect(keyword_whole_word.to_regex).to eq(/(?mix:\b#{Regexp.escape(keyword_whole_word.keyword)}\b)/)
      end

      it 'builds a regex with starting boundary and the keyword when end with non-word' do
        expect(keyword_end_non_word.to_regex).to eq(/(?mix:\btest\#)/)
      end

      it 'builds a regex with end boundary and the keyword when start with non-word' do
        expect(keyword_start_non_word.to_regex).to eq(/(?mix:\#test\b)/)
      end
    end

    context 'when whole_word is false' do
      let_it_be(:keyword_not_whole_word) { described_class.new(whole_word: false, keyword: 'test') }

      it 'builds a regex with the keyword' do
        expect(keyword_not_whole_word.to_regex).to eq(/test/i)
      end
    end
  end
end