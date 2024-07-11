# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrivacyController, type: :controller do
  render_views

  let_it_be(:controller) { described_class.new }

  describe 'GET #show' do
    it 'returns http success' do
      get :show
      expect(response).to have_http_status(200)
    end
  end
end