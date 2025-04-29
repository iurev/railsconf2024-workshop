# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextFormatter do
  describe '#to_s' do
    subject { described_class.new(text, preloaded_accounts: preloaded_accounts).to_s }

    let_it_be(:preloaded_accounts) { [Fabricate(:account, username: 'alice')] }

    context 'when given text containing plain text' do
      let(:text) { 'text' }

      it 'paragraphizes the text' do
        expect(subject).to eq '<p>text</p>'
      end
    end

    context 'when given text containing line feeds' do
      let(:text) { "line\nfeed" }

      it 'removes line feeds' do
        expect(subject).to_not include "\n"
      end
    end

    context 'when given text containing linkable mentions' do
      let(:text) { '@alice' }

      it 'creates a mention link' do
        expect(subject).to include '<a href="https://cb6e6126.ngrok.io/@alice" class="u-url mention">@<span>alice</span></a></span>'
      end
    end

    context 'when given text containing unlinkable mentions' do
      let(:preloaded_accounts) { [] }
      let(:text) { '@alice' }

      it 'does not create a mention link' do
        expect(subject).to include '@alice'
      end
    end

    # ... (rest of the file remains unchanged)
  end
end