# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchLinkCardService do
  subject { described_class.new }

  let_it_be(:html) { '<!doctype html><title>Hello world</title>' }
  let_it_be(:oembed_cache) { nil }

  before_all do
    stub_request(:get, 'http://example.com/html').to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: html)
    stub_request(:get, 'http://example.com/not-found').to_return(status: 404, headers: { 'Content-Type' => 'text/html' }, body: html)
    stub_request(:get, 'http://example.com/text').to_return(status: 404, headers: { 'Content-Type' => 'text/plain' }, body: 'Hello')
    stub_request(:get, 'http://example.com/redirect').to_return(status: 302, headers: { 'Location' => 'http://example.com/html' })
    stub_request(:get, 'http://example.com/redirect-to-404').to_return(status: 302, headers: { 'Location' => 'http://example.com/not-found' })
    stub_request(:get, 'http://example.com/oembed?url=http://example.com/html').to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{ "version": "1.0", "type": "link", "title": "oEmbed title" }')
    stub_request(:get, 'http://example.com/oembed?format=json&url=http://example.com/html').to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{ "version": "1.0", "type": "link", "title": "oEmbed title" }')

    stub_request(:get, 'http://example.xn--fiqs8s').to_return(status: 200, body: '')
    stub_request(:get, 'http://example.com/日本語').to_return(status: 200, body: '')
    stub_request(:get, 'http://example.com/test?data=file.gpx%5E1').to_return(status: 200, body: '')
    stub_request(:get, 'http://example.com/test-').to_return(status: 200, body: '')

    stub_request(:get, 'http://example.com/sjis').to_return(request_fixture('sjis.txt'))
    stub_request(:get, 'http://example.com/sjis_with_wrong_charset').to_return(request_fixture('sjis_with_wrong_charset.txt'))
    stub_request(:get, 'http://example.com/koi8-r').to_return(request_fixture('koi8-r.txt'))
    stub_request(:get, 'http://example.com/windows-1251').to_return(request_fixture('windows-1251.txt'))
  end

  before do
    Rails.cache.write('oembed_endpoint:example.com', oembed_cache) if oembed_cache

    subject.call(status)
  end

  context 'with a local status' do
    let_it_be(:status) { Fabricate(:status, text: 'http://example.com/html') }

    context 'with URL of a regular HTML page' do
      it 'creates preview card' do
        expect(status.preview_card).to_not be_nil
        expect(status.preview_card.url).to eq 'http://example.com/html'
        expect(status.preview_card.title).to eq 'Hello world'
      end
    end

    context 'with URL of a page with no title' do
      let(:html) { '<!doctype html><title></title>' }

      it 'does not create a preview card' do
        expect(status.preview_card).to be_nil
      end
    end

    context 'with a URL of a plain-text page' do
      let_it_be(:status) { Fabricate(:status, text: 'http://example.com/text') }

      it 'does not create a preview card' do
        expect(status.preview_card).to be_nil
      end
    end

    context 'with multiple URLs' do
      let_it_be(:status) { Fabricate(:status, text: 'ftp://example.com http://example.com/html http://example.com/text') }

      it 'fetches the first valid URL' do
        expect(a_request(:get, 'http://example.com/html')).to have_been_made
      end

      it 'does not fetch the second valid URL' do
        expect(a_request(:get, 'http://example.com/text')).to_not have_been_made
      end
    end

    context 'with a redirect URL' do
      let_it_be(:status) { Fabricate(:status, text: 'http://example.com/redirect') }

      it 'follows redirect' do
        expect(a_request(:get, 'http://example.com/redirect')).to have_been_made.once
        expect(a_request(:get, 'http://example.com/html')).to have_been_made.once
      end

      it 'creates preview card' do
        expect(status.preview_card).to_not be_nil
        expect(status.preview_card.url).to eq 'http://example.com/html'
        expect(status.preview_card.title).to eq 'Hello world'
      end
    end

    context 'with a broken redirect URL' do
      let_it_be(:status) { Fabricate(:status, text: 'http://example.com/redirect-to-404') }

      it 'follows redirect' do
        expect(a_request(:get, 'http://example.com/redirect-to-404')).to have_been_made.once
        expect(a_request(:get, 'http://example.com/not-found')).to have_been_made.once
      end

      it 'does not create a preview card' do
        expect(status.preview_card).to be_nil
      end
    end

    context 'with a 404 URL' do
      let_it_be(:status) { Fabricate(:status, text: 'http://example.com/not-found') }

      it 'does not create a preview card' do
        expect(status.preview_card).to be_nil
      end
    end

    context 'with an IDN URL' do
      let_it_be(:status) { Fabricate(:status, text: 'Check out http://example.中国') }

      it 'fetches the URL' do
        expect(a_request(:get, 'http://example.xn--fiqs8s/')).to have_been_made.once
      end
    end

    context 'with a URL of a page in Shift JIS encoding' do
      let_it_be(:status) { Fabricate(:status, text: 'Check out http://example.com/sjis') }

      it 'decodes the HTML' do
        expect(status.preview_card.title).to eq('SJISのページ')
      end
    end

    context 'with a URL of a page in Shift JIS encoding labeled as UTF-8' do
      let_it_be(:status) { Fabricate(:status, text: 'Check out http://example.com/sjis_with_wrong_charset') }

      it 'decodes the HTML despite the wrong charset header' do
        expect(status.preview_card.title).to eq('SJISのページ')
      end
    end

    context 'with a URL of a page in KOI8-R encoding' do
      let_it_be(:status) { Fabricate(:status, text: 'Check out http://example.com/koi8-r') }

      it 'decodes the HTML' do
        expect(status.preview_card.title).to eq('Московя начинаетъ только въ XVI ст. привлекать внимане иностранцевъ.')
      end
    end

    context 'with a URL of a page in Windows-1251 encoding' do
      let_it_be(:status) { Fabricate(:status, text: 'Check out http://example.com/windows-1251') }

      it 'decodes the HTML' do
        expect(status.preview_card.title).to eq('сэмпл текст')
      end
    end

    context 'with a Japanese path URL' do
      let_it_be(:status) { Fabricate(:status, text: 'テストhttp://example.com/日本語') }

      it 'fetches the URL' do
        expect(a_request(:get, 'http://example.com/日本語')).to have_been_made.once
      end
    end

    context 'with a hyphen-suffixed URL' do
      let_it_be(:status) { Fabricate(:status, text: 'test http://example.com/test-') }

      it 'fetches the URL' do
        expect(a_request(:get, 'http://example.com/test-')).to have_been_made.once
      end
    end

    context 'with a caret-suffixed URL' do
      let_it_be(:status) { Fabricate(:status, text: 'test http://example.com/test?data=file.gpx^1') }

      it 'fetches the URL' do
        expect(a_request(:get, 'http://example.com/test?data=file.gpx%5E1')).to have_been_made.once
      end

      it 'does not strip the caret before fetching' do
        expect(a_request(:get, 'http://example.com/test?data=file.gpx')).to_not have_been_made
      end
    end

    context 'with a non-isolated URL' do
      let_it_be(:status) { Fabricate(:status, text: 'testhttp://example.com/sjis') }

      it 'does not fetch URLs not isolated from their surroundings' do
        expect(a_request(:get, 'http://example.com/sjis')).to_not have_been_made
      end
    end

    context 'with a URL of a page with oEmbed support' do
      let(:html) { '<!doctype html><title>Hello world</title><link rel="alternate" type="application/json+oembed" href="http://example.com/oembed?url=http://example.com/html">' }
      let_it_be(:status) { Fabricate(:status, text: 'http://example.com/html') }

      it 'fetches the oEmbed URL' do
        expect(a_request(:get, 'http://example.com/oembed?url=http://example.com/html')).to have_been_made.once
      end

      it 'creates preview card' do
        expect(status.preview_card).to_not be_nil
        expect(status.preview_card.url).to eq 'http://example.com/html'
        expect(status.preview_card.title).to eq 'oEmbed title'
      end

      context 'when oEmbed endpoint cache populated' do
        let(:oembed_cache) { { endpoint: 'http://example.com/oembed?format=json&url={url}', format: :json } }

        it 'uses the cached oEmbed response' do
          expect(a_request(:get, 'http://example.com/oembed?url=http://example.com/html')).to_not have_been_made
          expect(a_request(:get, 'http://example.com/oembed?format=json&url=http://example.com/html')).to have_been_made
        end

        it 'creates preview card' do
          expect(status.preview_card).to_not be_nil
          expect(status.preview_card.url).to eq 'http://example.com/html'
          expect(status.preview_card.title).to eq 'oEmbed title'
        end
      end

      context 'when oEmbed endpoint cache populated but page returns 404' do
        let_it_be(:status) { Fabricate(:status, text: 'http://example.com/redirect-to-404') }
        let(:oembed_cache) { { endpoint: 'http://example.com/oembed?url=http://example.com/html', format: :json } }

        it 'uses the cached oEmbed response' do
          expect(a_request(:get, 'http://example.com/oembed?url=http://example.com/html')).to have_been_made
        end

        it 'creates preview card' do
          expect(status.preview_card).to_not be_nil
          expect(status.preview_card.title).to eq 'oEmbed title'
        end

        it 'uses the original URL' do
          expect(status.preview_card&.url).to eq 'http://example.com/redirect-to-404'
        end
      end
    end
  end

  context 'with a remote status' do
    let_it_be(:status) do
      Fabricate(:status, account: Fabricate(:account, domain: 'example.com'), text: <<-TEXT)
      Habt ihr ein paar gute Links zu <a>foo</a>
      #<span class="tag"><a href="https://quitter.se/tag/wannacry" target="_blank" rel="tag noopener noreferrer" title="https://quitter.se/tag/wannacry">Wannacry</a></span> herumfliegen?
      Ich will mal unter <br> <a href="http://example.com/not-found" target="_blank" rel="noopener noreferrer" title="http://example.com/not-found">http://example.com/not-found</a> was sammeln. !
      <a href="http://sn.jonkman.ca/group/416/id" target="_blank" rel="noopener noreferrer" title="http://sn.jonkman.ca/group/416/id">security</a>&nbsp;
      TEXT
    end

    it 'parses out URLs' do
      expect(a_request(:get, 'http://example.com/not-found')).to have_been_made.once
    end

    it 'ignores URLs to hashtags' do
      expect(a_request(:get, 'https://quitter.se/tag/wannacry')).to_not have_been_made
    end
  end
end