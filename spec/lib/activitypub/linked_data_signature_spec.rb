# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::LinkedDataSignature do
  include JsonLdHelper

  subject { described_class.new(json) }

  let_it_be(:sender) { Fabricate(:account, uri: 'http://example.com/alice', domain: 'example.com') }

  let(:raw_json) do
    {
      '@context' => 'https://www.w3.org/ns/activitystreams',
      'id' => 'http://example.com/hello-world',
    }
  end

  let(:json) { raw_json.merge('signature' => signature) }

  describe '#verify_actor!' do
    context 'when signature matches' do
      let(:raw_signature) do
        {
          'creator' => 'http://example.com/alice',
          'created' => '2017-09-23T20:21:34Z',
        }
      end

      let(:signature) { raw_signature.merge('type' => 'RsaSignature2017', 'signatureValue' => sign(sender, raw_signature, raw_json)) }

      it 'returns creator' do
        expect(subject.verify_actor!).to eq sender
      end
    end

    context 'when local account record is missing a public key' do
      let(:raw_signature) do
        {
          'creator' => 'http://example.com/alice',
          'created' => '2017-09-23T20:21:34Z',
        }
      end

      let(:service_stub) { instance_double(ActivityPub::FetchRemoteKeyService) }
      let(:signature) { raw_signature.merge('type' => 'RsaSignature2017', 'signatureValue' => 'dummySignature') }

      before(:all) do
        @old_key = sender.public_key
        @old_private_key = sender.private_key
        sender.update!(private_key: nil, public_key: nil)
      end

      after(:all) do
        sender.update!(private_key: @old_private_key, public_key: @old_key)
      end

      before do
        allow(ActivityPub::FetchRemoteKeyService).to receive(:new).and_return(service_stub)

        allow(service_stub).to receive(:call).with('http://example.com/alice') do
          sender.update!(public_key: @old_key)
          sender
        end
      end

      it 'fetches key and returns creator' do
        expect(subject.verify_actor!).to eq sender
        expect(service_stub).to have_received(:call).with('http://example.com/alice').once
      end
    end

    context 'when signature is missing' do
      let(:signature) { nil }

      it 'returns nil' do
        expect(subject.verify_actor!).to be_nil
      end
    end

    context 'when signature is tampered' do
      let(:raw_signature) do
        {
          'creator' => 'http://example.com/alice',
          'created' => '2017-09-23T20:21:34Z',
        }
      end

      let(:signature) { raw_signature.merge('type' => 'RsaSignature2017', 'signatureValue' => 's69F3mfddd99dGjmvjdjjs81e12jn121Gkm1') }

      it 'returns nil' do
        expect(subject.verify_actor!).to be_nil
      end
    end
  end

  describe '#sign!' do
    subject { described_class.new(raw_json).sign!(sender) }

    it 'returns a hash' do
      expect(subject).to be_a Hash
    end

    it 'contains signature' do
      expect(subject['signature']).to be_a Hash
      expect(subject['signature']['signatureValue']).to be_present
    end

    it 'can be verified again' do
      expect(described_class.new(subject).verify_actor!).to eq sender
    end
  end

  def sign(from_actor, options, document)
    return 'dummySignature' if from_actor.private_key.blank? && from_actor.public_key.blank?

    options_hash   = Digest::SHA256.hexdigest(canonicalize(options.merge('@context' => ActivityPub::LinkedDataSignature::CONTEXT)))
    document_hash  = Digest::SHA256.hexdigest(canonicalize(document))
    to_be_verified = options_hash + document_hash
    Base64.strict_encode64(from_actor.keypair.sign(OpenSSL::Digest.new('SHA256'), to_be_verified))
  end
end