# frozen_string_literal: true

require 'rails_helper'
require 'test_prof/recipes/let_it_be'

describe Admin::StatusesController, type: :controller do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:status) { Fabricate(:status, account: account, sensitive: true) }
  let_it_be(:media_attached_status) { Fabricate(:status, account: account, sensitive: true) }
  let_it_be(:last_media_attached_status) { Fabricate(:status, account: account, sensitive: true) }
  let_it_be(:media_attachment) { Fabricate(:media_attachment, account: account, status: last_media_attached_status) }
  let_it_be(:last_status) { Fabricate(:status, account: account) }
  let_it_be(:another_media_attachment) { Fabricate(:media_attachment, account: account, status: media_attached_status) }

  before do
    sign_in user, scope: :user
  end

  describe 'POST #batch' do
    subject { post :batch, params: { account_id: account.id, action: action, admin_status_batch_action: { status_ids: status_ids } } }

    let(:status_ids) { [media_attached_status.id] }
    let(:action) { 'report' }

    shared_examples 'when action is report' do
      it 'creates a report and redirects to report page' do
        expect { subject }.to change(Report, :count).by(1)

        report = Report.last
        expect(report).to have_attributes(
          target_account_id: account.id,
          status_ids: status_ids
        )

        expect(response).to redirect_to(admin_report_path(report.id))
      end
    end

    it_behaves_like 'when action is report'

    context 'when the moderator is blocked by the author' do
      before do
        account.block!(user.account)
      end

      it_behaves_like 'when action is report'
    end
  end
end