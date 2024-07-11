# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe ReportNotePolicy do
  subject { described_class }

  let_it_be(:admin) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')).account }
  let_it_be(:john)  { Fabricate(:account) }

  permissions :create? do
    context 'when staff?' do
      it 'permits' do
        expect(subject).to permit(admin, ReportNote)
      end
    end

    context 'with !staff?' do
      it 'denies' do
        expect(subject).to_not permit(john, ReportNote)
      end
    end
  end

  permissions :destroy? do
    let_it_be(:report_note) { Fabricate(:report_note) }

    context 'when admin?' do
      it 'permit' do
        expect(subject).to permit(admin, report_note)
      end
    end

    context 'when owner?' do
      let_it_be(:owner_report_note) { Fabricate(:report_note, account: john) }

      it 'permit' do
        expect(subject).to permit(john, owner_report_note)
      end
    end

    context 'with !owner?' do
      it 'denies' do
        expect(subject).to_not permit(john, report_note)
      end
    end
  end
end