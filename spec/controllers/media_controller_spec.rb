# frozen_string_literal: true

require 'rails_helper'

describe MediaController do
  render_views

  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:status) { Fabricate(:status, account: account) }
  let_it_be(:media_attachment) { Fabricate(:media_attachment, status: status, shortcode: 'OI6IgDzG-nYTqvDQ994') }

  describe '#show' do
    it 'raises when shortcode cant be found' do
      get :show, params: { id: 'missing' }

      expect(response).to have_http_status(404)
    end

    context 'when the media attachment has a shortcode' do
      it 'redirects to the file url when attached to a status' do
        get :show, params: { id: media_attachment.to_param }

        expect(response).to redirect_to(media_attachment.file.url(:original))
      end

      it 'responds with missing when there is not an attached status' do
        media_attachment.update!(status: nil)
        get :show, params: { id: media_attachment.to_param }

        expect(response).to have_http_status(404)
      end

      it 'raises when not permitted to view' do
        status.update!(visibility: :direct)
        get :show, params: { id: media_attachment.to_param }

        expect(response).to have_http_status(404)
      end
    end

    context 'when the media attachment has no shortcode' do
      before { media_attachment.update!(shortcode: nil) }

      it 'redirects to the file url when attached to a status' do
        get :show, params: { id: media_attachment.to_param }

        expect(response).to redirect_to(media_attachment.file.url(:original))
      end

      it 'responds with missing when there is not an attached status' do
        media_attachment.update!(status: nil)
        get :show, params: { id: media_attachment.to_param }

        expect(response).to have_http_status(404)
      end

      it 'raises when not permitted to view' do
        status.update!(visibility: :direct)
        get :show, params: { id: media_attachment.to_param }

        expect(response).to have_http_status(404)
      end
    end
  end
end
