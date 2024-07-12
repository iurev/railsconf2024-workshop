# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::TagsController do
  render_views

  let_it_be(:admin) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:tag) { Fabricate(:tag) }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    before do
      get :show, params: { id: tag.id }
    end

    it 'returns status 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'PUT #update' do
    before do
      tag.update(listable: false)
    end

    context 'with valid params' do
      it 'updates the tag' do
        put :update, params: { id: tag.id, tag: { listable: '1' } }

        expect(response).to redirect_to(admin_tag_path(tag.id))
        expect(tag.reload).to be_listable
      end
    end

    context 'with invalid params' do
      it 'does not update the tag' do
        put :update, params: { id: tag.id, tag: { name: 'cant-change-name' } }

        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
      end
    end
  end
end
