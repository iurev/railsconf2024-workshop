# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

describe Admin::StatusPolicy do
  let(:policy) { described_class }
  let_it_be(:admin)   { Fabricate(:user, role: UserRole.find_by(name: 'Admin')).account }
  let_it_be(:john)    { Fabricate(:account) }
  let_it_be(:status)  { Fabricate(:status) }

  permissions :index?, :update?, :review?, :destroy? do
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

  permissions :show? do
    context 'with an admin' do
      context 'with a public visible status' do
        it 'permits' do
          status.update!(visibility: :public)
          expect(policy).to permit(admin, status)
        end
      end

      context 'with a not public visible status' do
        it 'denies' do
          status.update!(visibility: :direct)
          expect(policy).to_not permit(admin, status)
        end

        context 'when the status mentions the admin' do
          it 'permits' do
            status.update!(visibility: :direct)
            status.mentions.create!(account: admin)
            expect(policy).to permit(admin, status)
          end
        end
      end
    end

    context 'with a non admin' do
      it 'denies' do
        expect(policy).to_not permit(john, status)
      end
    end
  end
end