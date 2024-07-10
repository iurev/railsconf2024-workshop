# frozen_string_literal: true

require 'rails_helper'

describe Admin::ReportNotesController do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }

  before_all do
    RSpec::Mocks.with_temporary_scope do
      sign_in user, scope: :user
    end
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    let_it_be(:report) { Fabricate(:report) }

    context 'when parameter is valid' do
      context 'when report is unsolved' do
        before { report.update(action_taken_at: nil, action_taken_by_account_id: nil) }

        context 'when create_and_resolve flag is on' do
          let(:params) { { report_note: { content: 'test content', report_id: report.id }, create_and_resolve: nil } }

          it 'creates a report note and resolves report' do
            expect { subject }.to change(ReportNote, :count).by(1)
            expect(report.reload).to be_action_taken
            expect(response).to redirect_to admin_reports_path
          end
        end

        context 'when create_and_resolve flag is false' do
          let(:params) { { report_note: { content: 'test content', report_id: report.id } } }

          it 'creates a report note and does not resolve report' do
            expect { subject }.to change(ReportNote, :count).by(1)
            expect(report.reload).to_not be_action_taken
            expect(response).to redirect_to admin_report_path(report)
          end
        end
      end

      context 'when report is resolved' do
        before { report.update(action_taken_at: Time.now.utc, action_taken_by_account_id: user.account.id) }

        context 'when create_and_unresolve flag is on' do
          let(:params) { { report_note: { content: 'test content', report_id: report.id }, create_and_unresolve: nil } }

          it 'creates a report note and unresolves report' do
            expect { subject }.to change(ReportNote, :count).by(1)
            expect(report.reload).to_not be_action_taken
            expect(response).to redirect_to admin_report_path(report)
          end
        end

        context 'when create_and_unresolve flag is false' do
          let(:params) { { report_note: { content: 'test content', report_id: report.id } } }

          it 'creates a report note and does not unresolve report' do
            expect { subject }.to change(ReportNote, :count).by(1)
            expect(report.reload).to be_action_taken
            expect(response).to redirect_to admin_report_path(report)
          end
        end
      end
    end

    context 'when parameter is invalid' do
      let(:params) { { report_note: { content: '', report_id: report.id } } }

      it 'renders admin/reports/show' do
        expect(subject).to render_template 'admin/reports/show'
      end
    end
  end

  describe 'DELETE #destroy' do
    subject { delete :destroy, params: { id: report_note.id } }

    let_it_be(:report_note) { Fabricate(:report_note) }

    it 'deletes note' do
      expect { subject }.to change(ReportNote, :count).by(-1)
      expect(response).to redirect_to admin_report_path(report_note.report)
    end
  end
end