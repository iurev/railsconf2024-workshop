# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

describe FollowRecommendationPolicy do
  let(:policy) { described_class }
  let_it_be(:admin_role) { UserRole.find_by(name: 'Admin') }
  let_it_be(:admin) { Fabricate(:user, role: admin_role).account }
  let_it_be(:john)  { Fabricate(:account) }

  describe 'permissions' do
    it 'permits admin and denies non-admin for show?, suppress?, and unsuppress?', :aggregate_failures do
      %i[show? suppress? unsuppress?].each do |permission|
        expect(policy).to permit(admin, Tag), "expected to permit #{permission} for admin"
        expect(policy).not_to permit(john, Tag), "expected not to permit #{permission} for non-admin"
      end
    end
  end
end