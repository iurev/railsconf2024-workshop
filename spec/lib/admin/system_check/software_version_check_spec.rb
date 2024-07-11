# frozen_string_literal: true

require 'rails_helper'

describe Admin::SystemCheck::SoftwareVersionCheck do
  include RoutingHelper

  let_it_be(:user) { Fabricate(:user) }

  subject(:check) { described_class.new(user) }

  shared_context 'with software update' do |version: '99.99.99', type: 'patch', urgent: false|
    before { Fabricate(:software_update, version: version, type: type, urgent: urgent) }
  end

  describe 'skip?' do
    context 'when user cannot view devops' do
      before { allow(user).to receive(:can?).with(:view_devops).and_return(false) }

      it 'returns true' do
        expect(check.skip?).to be true
      end
    end

    context 'when user can view devops' do
      before { allow(user).to receive(:can?).with(:view_devops).and_return(true) }

      it 'returns false' do
        expect(check.skip?).to be false
      end

      context 'when checks are disabled' do
        around do |example|
          ClimateControl.modify UPDATE_CHECK_URL: '' do
            example.run
          end
        end

        it 'returns true' do
          expect(check.skip?).to be true
        end
      end
    end
  end

  describe 'pass?' do
    context 'when there is no known update' do
      it 'returns true' do
        expect(check.pass?).to be true
      end
    end

    context 'when there is a non-urgent major release' do
      include_context 'with software update', type: 'major', urgent: false

      it 'returns true' do
        expect(check.pass?).to be true
      end
    end

    context 'when there is an urgent major release' do
      include_context 'with software update', type: 'major', urgent: true

      it 'returns false' do
        expect(check.pass?).to be false
      end
    end

    context 'when there is an urgent minor release' do
      include_context 'with software update', type: 'minor', urgent: true

      it 'returns false' do
        expect(check.pass?).to be false
      end
    end

    context 'when there is an urgent patch release' do
      include_context 'with software update', type: 'patch', urgent: true

      it 'returns false' do
        expect(check.pass?).to be false
      end
    end

    context 'when there is a non-urgent patch release' do
      include_context 'with software update', type: 'patch', urgent: false

      it 'returns false' do
        expect(check.pass?).to be false
      end
    end
  end

  describe 'message' do
    context 'when there is a non-urgent patch release pending' do
      include_context 'with software update', type: 'patch', urgent: false

      it 'sends class name symbol to message instance' do
        allow(Admin::SystemCheck::Message).to receive(:new)
          .with(:software_version_patch_check, anything, anything)

        check.message

        expect(Admin::SystemCheck::Message).to have_received(:new)
          .with(:software_version_patch_check, nil, admin_software_updates_path)
      end
    end

    context 'when there is an urgent patch release pending' do
      include_context 'with software update', type: 'patch', urgent: true

      it 'sends class name symbol to message instance' do
        allow(Admin::SystemCheck::Message).to receive(:new)
          .with(:software_version_critical_check, anything, anything, anything)

        check.message

        expect(Admin::SystemCheck::Message).to have_received(:new)
          .with(:software_version_critical_check, nil, admin_software_updates_path, true)
      end
    end
  end
end