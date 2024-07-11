# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

describe AccountWarningPresetPolicy do
  before_all do
    UserRole.find_or_create_by(name: 'Admin')
  end

  let_it_be(:admin) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')).account }
  let_it_be(:john)  { Fabricate(:account) }

  permissions :index?, :create?, :update?, :destroy? do
    context 'with an admin' do
      it 'permits' do
        expect(described_class).to permit(admin, Tag)
      end
    end

    context 'with a non-admin' do
      it 'denies' do
        expect(described_class).to_not permit(john, Tag)
      end
    end
  end
end