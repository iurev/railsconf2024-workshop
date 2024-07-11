# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HtmlAwareFormatter do
  describe '#to_s' do
    subject { described_class.new(text, local).to_s }

    context 'when local' do
      let_it_be(:local) { true }
      let_it_be(:text) { 'Foo bar' }

      it 'returns formatted text' do
        expect(subject).to eq '<p>Foo bar</p>'
      end
    end

    context 'when remote' do
      let_it_be(:local) { false }

      context 'when given plain text' do
        let_it_be(:text) { 'Beep boop' }

        it 'keeps the plain text' do
          expect(subject).to include 'Beep boop'
        end
      end

      context 'when given text containing script tags' do
        let_it_be(:text) { '<script>alert("Hello")</script>' }

        it 'strips the scripts' do
          expect(subject).to_not include '<script>alert("Hello")</script>'
        end
      end

      context 'when given text containing malicious classes' do
        let_it_be(:text) { '<span class="mention  status__content__spoiler-link">Show more</span>' }

        it 'strips the malicious classes' do
          expect(subject).to_not include 'status__content__spoiler-link'
        end
      end
    end
  end
end