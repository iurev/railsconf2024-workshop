# frozen_string_literal: true

require 'rails_helper'

describe Admin::RolesController do
  render_views

  let_it_be(:permissions)  { UserRole::Flags::NONE }
  let_it_be(:current_role) { UserRole.create(name: 'Foo', permissions: permissions, position: 10) }
  let_it_be(:current_user) { Fabricate(:user, role: current_role) }

  before do
    sign_in current_user, scope: :user
  end

  describe 'GET #index' do
    context 'when user does not have permission to manage roles' do
      before do
        get :index
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when user has permission to manage roles' do
      before do
        current_role.update!(permissions: UserRole::FLAGS[:manage_roles])
        get :index
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #new' do
    context 'when user does not have permission to manage roles' do
      it 'returns http forbidden' do
        get :new
        expect(response).to have_http_status(403)
      end
    end

    context 'when user has permission to manage roles' do
      before { current_role.update!(permissions: UserRole::FLAGS[:manage_roles]) }

      it 'returns http success' do
        get :new
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST #create' do
    let(:selected_position) { 1 }
    let(:selected_permissions_as_keys) { %w(manage_roles) }

    context 'when user has permission to manage roles' do
      before { current_role.update!(permissions: UserRole::FLAGS[:manage_roles]) }

      context 'when new role\'s does not elevate above the user\'s role' do
        it 'redirects to roles page' do
          post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: selected_permissions_as_keys } }
          expect(response).to redirect_to(admin_roles_path)
        end

        it 'creates new role' do
          expect {
            post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: selected_permissions_as_keys } }
          }.to change(UserRole, :count).by(1)
        end
      end

      context 'when new role\'s position is higher than user\'s role' do
        let(:selected_position) { 100 }

        it 'renders new template' do
          post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: selected_permissions_as_keys } }
          expect(response).to render_template(:new)
        end

        it 'does not create new role' do
          expect {
            post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: selected_permissions_as_keys } }
          }.not_to change(UserRole, :count)
        end
      end

      context 'when new role has permissions the user does not have' do
        let(:selected_permissions_as_keys) { %w(manage_roles manage_users manage_reports) }

        it 'renders new template' do
          post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: selected_permissions_as_keys } }
          expect(response).to render_template(:new)
        end

        it 'does not create new role' do
          expect {
            post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: selected_permissions_as_keys } }
          }.not_to change(UserRole, :count)
        end
      end

      context 'when user has administrator permission' do
        before { current_role.update!(permissions: UserRole::FLAGS[:administrator]) }

        it 'redirects to roles page' do
          post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: %w(manage_roles manage_users manage_reports) } }
          expect(response).to redirect_to(admin_roles_path)
        end

        it 'creates new role' do
          expect {
            post :create, params: { user_role: { name: 'Bar', position: selected_position, permissions_as_keys: %w(manage_roles manage_users manage_reports) } }
          }.to change(UserRole, :count).by(1)
        end
      end
    end
  end

  describe 'GET #edit' do
    let_it_be(:role) { UserRole.create(name: 'Bar', permissions: UserRole::FLAGS[:manage_users], position: 8) }

    context 'when user does not have permission to manage roles' do
      it 'returns http forbidden' do
        get :edit, params: { id: role.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'when user has permission to manage roles' do
      before { current_role.update!(permissions: UserRole::FLAGS[:manage_roles]) }

      context 'when user outranks the role' do
        it 'returns http success' do
          get :edit, params: { id: role.id }
          expect(response).to have_http_status(:success)
        end
      end

      context 'when role outranks user' do
        before { role.update!(position: current_role.position + 1) }

        it 'returns http forbidden' do
          get :edit, params: { id: role.id }
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'PUT #update' do
    let_it_be(:role) { UserRole.create(name: 'Bar', permissions: UserRole::FLAGS[:manage_users], position: 8) }

    context 'when user does not have permission to manage roles' do
      it 'returns http forbidden' do
        put :update, params: { id: role.id, user_role: { name: 'Baz' } }
        expect(response).to have_http_status(403)
      end

      it 'does not update the role' do
        expect {
          put :update, params: { id: role.id, user_role: { name: 'Baz' } }
        }.not_to change { role.reload.name }
      end
    end

    context 'when user has permission to manage roles' do
      before { current_role.update!(permissions: UserRole::FLAGS[:manage_roles]) }

      context 'when role has permissions the user doesn\'t' do
        it 'renders edit template' do
          put :update, params: { id: role.id, user_role: { name: 'Baz' } }
          expect(response).to render_template(:edit)
        end

        it 'does not update the role' do
          expect {
            put :update, params: { id: role.id, user_role: { name: 'Baz' } }
          }.not_to change { role.reload.name }
        end
      end

      context 'when user has all permissions of the role' do
        before { current_role.update!(permissions: UserRole::FLAGS[:manage_roles] | UserRole::FLAGS[:manage_users]) }

        context 'when user outranks the role' do
          it 'redirects to roles page' do
            put :update, params: { id: role.id, user_role: { name: 'Baz' } }
            expect(response).to redirect_to(admin_roles_path)
          end

          it 'updates the role' do
            expect {
              put :update, params: { id: role.id, user_role: { name: 'Baz' } }
            }.to change { role.reload.name }.to('Baz')
          end
        end

        context 'when role outranks user' do
          before { role.update!(position: current_role.position + 1) }

          it 'returns http forbidden' do
            put :update, params: { id: role.id, user_role: { name: 'Baz' } }
            expect(response).to have_http_status(403)
          end

          it 'does not update the role' do
            expect {
              put :update, params: { id: role.id, user_role: { name: 'Baz' } }
            }.not_to change { role.reload.name }
          end
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:role) { UserRole.create(name: 'Bar', permissions: UserRole::FLAGS[:manage_users], position: 8) }

    context 'when user does not have permission to manage roles' do
      it 'returns http forbidden' do
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'when user has permission to manage roles' do
      before { current_role.update!(permissions: UserRole::FLAGS[:manage_roles]) }

      context 'when user outranks the role' do
        it 'redirects to roles page' do
          delete :destroy, params: { id: role.id }
          expect(response).to redirect_to(admin_roles_path)
        end
      end

      context 'when role outranks user' do
        before { role.update!(position: current_role.position + 1) }

        it 'returns http forbidden' do
          delete :destroy, params: { id: role.id }
          expect(response).to have_http_status(403)
        end
      end
    end
  end
end