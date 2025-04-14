# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe CustomEmojiPolicy do
  subject { described_class }

  let_it_be(:admin_role) { UserRole.find_by(name: 'Admin') }
  let_it_be(:admin)      { Fabricate(:user, role: admin_role).account }
  let_it_be(:john)       { Fabricate(:account) }

  permissions :index?, :enable?, :disable? do
    context 'when staff' do
      it 'permits' do
        expect(subject).to permit(admin, CustomEmoji)
      end
    end

    context 'when not staff' do
      it 'denies' do
        expect(subject).to_not permit(john, CustomEmoji)
      end
    end
  end

  permissions :create?, :update?, :copy?, :destroy? do
    context 'when admin' do
      it 'permits' do
        expect(subject).to permit(admin, CustomEmoji)
      end
    end

    context 'when not admin' do
      it 'denies' do
        expect(subject).to_not permit(john, CustomEmoji)
      end
    end
  end
end