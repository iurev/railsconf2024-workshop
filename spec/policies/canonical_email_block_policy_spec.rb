# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

describe CanonicalEmailBlockPolicy do
  let_it_be(:policy) { described_class }
  let_it_be(:john)   { Fabricate(:account) }

  permissions :index?, :show?, :test?, :create?, :destroy? do
    context 'with an admin', :account do
      before do
        account.user.update(role: UserRole.find_by(name: 'Admin'))
      end

      it 'permits' do
        expect(policy).to permit(account, Tag)
      end
    end

    context 'with a non-admin' do
      it 'denies' do
        expect(policy).to_not permit(john, Tag)
      end
    end
  end
end