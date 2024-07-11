# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe BackupPolicy do
  subject { described_class }

  let_it_be(:john) { Fabricate(:account) }

  permissions :create? do
    context 'when not user_signed_in?' do
      it 'denies' do
        expect(subject).to_not permit(nil, Backup)
      end
    end

    context 'when user_signed_in?' do
      context 'with no backups' do
        it 'permits' do
          expect(subject).to permit(john, Backup)
        end
      end

      context 'when backups are too old' do
        before_all do
          travel(-8.days) do
            Fabricate(:backup, user: john.user)
          end
        end

        it 'permits' do
          expect(subject).to permit(john, Backup)
        end
      end

      context 'when backups are newer' do
        before_all do
          travel(-3.days) do
            Fabricate(:backup, user: john.user)
          end
        end

        it 'denies' do
          expect(subject).to_not permit(john, Backup)
        end
      end
    end
  end
end