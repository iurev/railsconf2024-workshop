# frozen_string_literal: true

require 'rails_helper'

describe Admin::StatusesController do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:status) { Fabricate(:status, account: account) }
  let_it_be(:sensitive) { true }
  let_it_be(:media_attached_status) { Fabricate(:status, account: account, sensitive: !sensitive) }
  let_it_be(:last_media_attached_status) { Fabricate(:status, account: account, sensitive: !sensitive) }

  before_all do
    Fabricate(:media_attachment, account: account, status: last_media_attached_status)
    Fabricate(:status, account: account)
    Fabricate(:media_attachment, account: account, status: media_attached_status)
  end

  before do
    sign_in user, scope: :user
  end

  describe 'GET #index' do
    it 'returns http success with a valid account' do
      get :index, params: { account_id: account.id }
      expect(response).to have_http_status(200)
    end

    it 'returns http success when filtering by media' do
      get :index, params: { account_id: account.id, media: '1' }
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { account_id: account.id, id: status.id }
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #batch' do
    subject { post :batch, params: { :account_id => account.id, action => '', :admin_status_batch_action => { status_ids: status_ids } } }

    let(:status_ids) { [media_attached_status.id] }
    let(:action) { 'report' }

    shared_examples 'creates a report and redirects' do
      it 'creates a report and redirects to report page' do
        subject

        expect(Report.last)
          .to have_attributes(
            target_account_id: eq(account.id),
            status_ids: eq(status_ids)
          )

        expect(response).to redirect_to(admin_report_path(Report.last.id))
      end
    end

    it_behaves_like 'creates a report and redirects'

    context 'when the moderator is blocked by the author' do
      before do
        account.block!(user.account)
      end

      it_behaves_like 'creates a report and redirects'
    end
  end
end