# frozen_string_literal: true

require 'rails_helper'

describe Admin::Users::RolesController do
  render_views

  let_it_be(:current_role) { UserRole.create(name: 'Foo', permissions: UserRole::FLAGS[:manage_roles], position: 10) }
  let_it_be(:current_user) { Fabricate(:user, role: current_role) }
  let_it_be(:user) { Fabricate(:user) }

  before_all do
    sign_in current_user, scope: :user
  end

  describe 'GET #show' do
    before do
      get :show, params: { user_id: user.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    context 'when target user is higher ranked than current user' do
      let_it_be(:previous_role) { UserRole.create(name: 'Baz', permissions: UserRole::FLAGS[:administrator], position: 100) }

      before do
        user.update(role: previous_role)
        get :show, params: { user_id: user.id }
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'PUT #update' do
    let_it_be(:selected_role) { UserRole.create(name: 'Bar', permissions: UserRole::FLAGS[:manage_roles], position: 1) }

    before do
      put :update, params: { user_id: user.id, user: { role_id: selected_role.id } }
    end

    context 'with manage roles permissions' do
      it 'updates user role' do
        expect(user.reload.role_id).to eq selected_role&.id
      end

      it 'redirects back to account page' do
        expect(response).to redirect_to(admin_account_path(user.account_id))
      end
    end

    context 'when selected role has higher position than current user\'s role' do
      let_it_be(:higher_role) { UserRole.create(name: 'Higher', permissions: UserRole::FLAGS[:administrator], position: 100) }

      before do
        put :update, params: { user_id: user.id, user: { role_id: higher_role.id } }
      end

      it 'does not update user role' do
        expect(user.reload.role_id).to be_nil
      end

      it 'renders edit form' do
        expect(response).to render_template(:show)
      end
    end

    context 'when target user is higher ranked than current user' do
      let_it_be(:previous_role) { UserRole.create(name: 'Baz', permissions: UserRole::FLAGS[:administrator], position: 100) }

      before do
        user.update(role: previous_role)
        put :update, params: { user_id: user.id, user: { role_id: selected_role.id } }
      end

      it 'does not update user role' do
        expect(user.reload.role_id).to eq previous_role&.id
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end
  end
end