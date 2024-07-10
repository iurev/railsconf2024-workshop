# frozen_string_literal: true

require 'rails_helper'

describe ResolveURLService do
  subject { described_class.new }

  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:poster)  { Fabricate(:account, domain: 'example.com') }
  let_it_be(:status)  { Fabricate(:status, account: poster, visibility: :private) }

  describe '#call' do
    it 'returns nil when there is no resource url' do
      url = 'http://example.com/missing-resource'
      Fabricate(:account, uri: url, domain: 'example.com')
      service = instance_double(FetchResourceService)

      allow(FetchResourceService).to receive(:new).and_return service
      allow(service).to receive(:response_code).and_return(404)
      allow(service).to receive(:call).with(url).and_return(nil)

      expect(subject.call(url)).to be_nil
    end

    it 'returns known account on temporary error' do
      url           = 'http://example.com/missing-resource'
      known_account = Fabricate(:account, uri: url, domain: 'example.com')
      service = instance_double(FetchResourceService)

      allow(FetchResourceService).to receive(:new).and_return service
      allow(service).to receive(:response_code).and_return(500)
      allow(service).to receive(:call).with(url).and_return(nil)

      expect(subject.call(url)).to eq known_account
    end

    shared_examples 'remote private status' do
      before do
        stub_request(:get, url).to_return(status: 404) if defined?(url)
        stub_request(:get, uri).to_return(status: 404) if defined?(uri)
      end

      context 'when the account follows the poster' do
        before do
          account.follow!(poster)
        end

        it 'returns status by url' do
          expect(subject.call(url, on_behalf_of: account)).to eq(status)
        end

        it 'returns status by uri' do
          expect(subject.call(uri, on_behalf_of: account)).to eq(status)
        end
      end

      context 'when the account does not follow the poster' do
        it 'does not return the status by url' do
          expect(subject.call(url, on_behalf_of: account)).to be_nil
        end

        it 'does not return the status by uri' do
          expect(subject.call(uri, on_behalf_of: account)).to be_nil
        end
      end
    end

    context 'when searching for a remote private status' do
      context 'when the status uses Mastodon-style URLs' do
        let(:url) { 'https://example.com/@foo/42' }
        let(:uri) { 'https://example.com/users/foo/statuses/42' }

        before do
          status.update!(url: url, uri: uri)
        end

        include_examples 'remote private status'
      end

      context 'when the status uses pleroma-style URLs' do
        let(:uri) { 'https://example.com/objects/0123-456-789-abc-def' }

        before do
          status.update!(url: nil, uri: uri)
        end

        include_examples 'remote private status'
      end
    end

    context 'when searching for a local private status' do
      let(:url) { ActivityPub::TagManager.instance.url_for(status) }
      let(:uri) { ActivityPub::TagManager.instance.uri_for(status) }

      include_examples 'remote private status'
    end

    context 'when searching for a link that redirects to a local public status' do
      let_it_be(:public_status) { Fabricate(:status, account: poster, visibility: :public) }
      let(:url)     { 'https://link.to/foobar' }
      let(:status_url) { ActivityPub::TagManager.instance.url_for(public_status) }
      let(:uri) { ActivityPub::TagManager.instance.uri_for(public_status) }

      before do
        stub_request(:get, url).to_return(status: 302, headers: { 'Location' => status_url })
        body = ActiveModelSerializers::SerializableResource.new(public_status, serializer: ActivityPub::NoteSerializer, adapter: ActivityPub::Adapter).to_json
        stub_request(:get, status_url).to_return(body: body, headers: { 'Content-Type' => 'application/activity+json' })
        stub_request(:get, uri).to_return(body: body, headers: { 'Content-Type' => 'application/activity+json' })
      end

      it 'returns status by url' do
        expect(subject.call(url, on_behalf_of: account)).to eq(public_status)
      end
    end

    context 'when searching for a local link of a remote private status' do
      let(:url)        { 'https://example.com/@foo/42' }
      let(:uri)        { 'https://example.com/users/foo/statuses/42' }
      let(:search_url) { "https://#{Rails.configuration.x.local_domain}/@foo@example.com/#{status.id}" }

      before do
        status.update!(url: url, uri: uri)
      end

      include_examples 'remote private status'
    end
  end
end