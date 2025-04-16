# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlainTextFormatter do
  describe '#to_s' do
    subject { described_class.new(status.text, status.local?).to_s }

    context 'when status is local' do
      let_it_be(:status) { Fabricate(:status, text: '<p>a text by a nerd who uses an HTML tag in text</p>', uri: nil) }

      it 'returns the raw text' do
        expect(subject).to eq '<p>a text by a nerd who uses an HTML tag in text</p>'
      end
    end

    context 'when status is remote' do
      let_it_be(:remote_account) { Fabricate(:account, domain: 'remote.test', username: 'bob', url: 'https://remote.test/') }
      let_it_be(:status) { Fabricate(:status, account: remote_account, text: 'Base text') }

      context 'when text contains inline HTML tags' do
        before { status.update!(text: '<b>Lorem</b> <em>ipsum</em>') }

        it 'strips the tags' do
          expect(subject).to eq 'Lorem ipsum'
        end
      end

      context 'when text contains <p> tags' do
        before { status.update!(text: '<p>Lorem</p><p>ipsum</p>') }

        it 'inserts a newline' do
          expect(subject).to eq "Lorem\nipsum"
        end
      end

      context 'when text contains a single <br> tag' do
        before { status.update!(text: 'Lorem<br>ipsum') }

        it 'inserts a newline' do
          expect(subject).to eq "Lorem\nipsum"
        end
      end

      context 'when text contains consecutive <br> tag' do
        before { status.update!(text: 'Lorem<br><br><br>ipsum') }

        it 'inserts a single newline' do
          expect(subject).to eq "Lorem\nipsum"
        end
      end

      context 'when text contains HTML entity' do
        before { status.update!(text: 'Lorem &amp; ipsum &#x2764;') }

        it 'unescapes the entity' do
          expect(subject).to eq 'Lorem & ipsum ❤'
        end
      end

      context 'when text contains <script> tag' do
        before { status.update!(text: 'Lorem <script> alert("Booh!") </script>ipsum') }

        it 'strips the tag and its contents' do
          expect(subject).to eq 'Lorem ipsum'
        end
      end

      context 'when text contains an HTML comment tags' do
        before { status.update!(text: 'Lorem <!-- Booh! -->ipsum') }

        it 'strips the comment' do
          expect(subject).to eq 'Lorem ipsum'
        end
      end
    end
  end
end