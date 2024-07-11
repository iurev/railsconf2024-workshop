# frozen_string_literal: true

require 'rails_helper'

describe Poll do
  describe 'scopes' do
    let_it_be(:status) { Fabricate(:status) }
    let_it_be(:attached_poll) { Fabricate(:poll, status: status) }
    let_it_be(:not_attached_poll) do
      Fabricate(:poll).tap do |poll|
        poll.status = nil
        poll.save(validate: false)
      end
    end

    describe 'attached' do
      it 'finds the correct records' do
        results = described_class.attached

        expect(results).to eq([attached_poll])
      end
    end

    describe 'unattached' do
      it 'finds the correct records' do
        results = described_class.unattached

        expect(results).to eq([not_attached_poll])
      end
    end
  end

  describe 'validations' do
    let_it_be(:valid_poll) { Fabricate.build(:poll) }
    let_it_be(:invalid_poll) { Fabricate.build(:poll, expires_at: nil) }

    context 'when valid' do
      it 'is valid with valid attributes' do
        expect(valid_poll).to be_valid
      end
    end

    context 'when not valid' do
      it 'is invalid without an expire date' do
        invalid_poll.valid?
        expect(invalid_poll).to model_have_error_on_field(:expires_at)
      end
    end
  end
end