# frozen_string_literal: true

require 'rails_helper'

describe Admin::ActionLogsController do
  render_views

  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:admin) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }

  before_all do
    orphaned_log_types.each do |type|
      Fabricate(:action_log, account: account, action: 'destroy', target_type: type, target_id: 1312)
    end
  end

  describe 'GET #index' do
    it 'returns 200' do
      sign_in admin
      get :index, params: { page: 1 }

      expect(response).to have_http_status(200)
    end
  end

  private

  def orphaned_log_types
    %w(
      Account
      AccountWarning
      Announcement
      Appeal
      CanonicalEmailBlock
      CustomEmoji
      DomainAllow
      DomainBlock
      EmailDomainBlock
      Instance
      IpBlock
      Report
      Status
      UnavailableDomain
      User
      UserRole
    )
  end
end