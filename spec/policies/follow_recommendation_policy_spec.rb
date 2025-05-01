# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

describe FollowRecommendationPolicy do
  let(:policy) { described_class }
  let_it_be(:admin_role) { UserRole.find_by(name: 'Admin') }
  let_it_be(:admin) { Fabricate(:user, role: admin_role).account }
  let_it_be(:john)  { Fabricate(:account) }

  permissions :show?, :suppress?, :unsuppress? do
    context 'with an admin' do
      it 'permits' do
        expect(policy).to permit(admin, Tag)
      end
    end

    context 'with a non-admin' do
      it 'denies' do
        expect(policy).to_not permit(john, Tag)
      end
    end
  end
end