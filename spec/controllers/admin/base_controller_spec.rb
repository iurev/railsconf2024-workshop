# frozen_string_literal: true

require 'rails_helper'

describe Admin::BaseController do
  controller do
    def success
      authorize :dashboard, :index?
      render 'admin/reports/show'
    end
  end

  let_it_be(:user) { Fabricate(:user) }

  before do
    routes.draw { get 'success' => 'admin/base#success' }
  end

  it 'requires administrator or moderator' do
    sign_in(user)
    get :success

    expect(response).to have_http_status(403)
  end

  context 'when user is a moderator' do
    before do
      user.update!(role: UserRole.find_by(name: 'Moderator'))
      sign_in(user)
    end

    it 'returns private cache control headers' do
      get :success
      expect(response.headers['Cache-Control']).to include('private, no-store')
    end

    it 'renders admin layout' do
      get :success
      expect(response).to render_template layout: 'admin'
    end
  end

  context 'when user is an admin' do
    before do
      user.update!(role: UserRole.find_by(name: 'Admin'))
      sign_in(user)
    end

    it 'renders admin layout' do
      get :success
      expect(response).to render_template layout: 'admin'
    end
  end
end