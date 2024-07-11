# frozen_string_literal: true

require 'rails_helper'

describe MediaProxyController do
  render_views

  before do
    stub_request(:get, 'http://example.com/attachment.png').to_return(request_fixture('avatar.txt'))
  end

  let_it_be(:status) { Fabricate(:status) }
  let_it_be(:media_attachment) { Fabricate(:media_attachment, status: status, remote_url: 'http://example.com/attachment.png') }

  describe '#show' do
    it 'redirects when attached to a status' do
      get :show, params: { id: media_attachment.id }

      expect(response).to have_http_status(302)
    end

    it 'responds with missing when there is not an attached status' do
      media_attachment.update!(status: nil)
      get :show, params: { id: media_attachment.id }

      expect(response).to have_http_status(404)
    end

    it 'raises when id cant be found' do
      get :show, params: { id: 'missing' }

      expect(response).to have_http_status(404)
    end

    it 'raises when not permitted to view' do
      direct_status = Fabricate(:status, visibility: :direct)
      direct_media_attachment = Fabricate(:media_attachment, status: direct_status, remote_url: 'http://example.com/attachment.png')
      get :show, params: { id: direct_media_attachment.id }

      expect(response).to have_http_status(404)
    end
  end
end