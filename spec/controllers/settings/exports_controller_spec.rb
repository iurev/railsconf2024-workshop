# frozen_string_literal: true

require 'rails_helper'

describe Settings::ExportsController, :user do
  render_views

  let_it_be(:user) { Fabricate(:user) }

  describe 'GET #show' do
    context 'when signed in' do
      before do
        sign_in user, scope: :user
        get :show
      end

      it 'returns http success with private cache control headers', :aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.headers['Cache-Control']).to include('private, no-store')
      end
    end

    context 'when not signed in' do
      it 'redirects' do
        get :show
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end

  describe 'POST #create' do
    before do
      sign_in user, scope: :user
    end

    it 'redirects to settings_export_path' do
      post :create
      expect(response).to redirect_to(settings_export_path)
    end

    it 'queues BackupWorker job by 1' do
      Sidekiq::Testing.fake!

      expect do
        post :create
      end.to change(BackupWorker.jobs, :size).by(1)
    end
  end
end