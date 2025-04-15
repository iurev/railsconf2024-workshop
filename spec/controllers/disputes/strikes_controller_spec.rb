# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Disputes::StrikesController do
  render_views

  let_it_be(:current_user) { Fabricate(:user) }

  describe '#show' do
    before do
      sign_in current_user, scope: :user
      get :show, params: { id: strike.id }
    end

    let(:strike) { Fabricate(:account_warning, target_account: current_user.account) }

    context 'when meant for the user' do
      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when meant for a different user' do
      let(:strike) { Fabricate(:account_warning) }

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end
  end
end