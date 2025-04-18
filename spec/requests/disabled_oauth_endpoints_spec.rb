# frozen_string_literal: true

require 'rails_helper'

describe 'Disabled OAuth routes' do
  let_it_be(:application) { Fabricate(:application, scopes: 'read') }

  # These routes are disabled via the doorkeeper configuration for
  # `admin_authenticator`, as these routes should only be accessible by server
  # administrators. For now, these routes are not properly designed and
  # integrated into Mastodon, so we're disabling them completely
  {
    'GET /oauth/applications' => :oauth_applications_path,
    'POST /oauth/applications' => :oauth_applications_path,
    'GET /oauth/applications/new' => :new_oauth_application_path,
    'GET /oauth/applications/:id' => :oauth_application_path,
    'PATCH /oauth/applications/:id' => :oauth_application_path,
    'PUT /oauth/applications/:id' => :oauth_application_path,
    'DELETE /oauth/applications/:id' => :oauth_application_path,
    'GET /oauth/applications/:id/edit' => :edit_oauth_application_path
  }.each do |description, path_helper|
    describe description do
      it 'returns 403 forbidden' do
        method = description.split.first.downcase

        if path_helper == :oauth_application_path || path_helper == :edit_oauth_application_path
          send(method, send(path_helper, application))
        else
          send(method, send(path_helper))
        end

        expect(response).to have_http_status(403)
      end
    end
  end
end