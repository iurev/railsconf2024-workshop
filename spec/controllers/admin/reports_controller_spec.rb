# frozen_string_literal: true

require 'rails_helper'

describe Admin::ReportsController do
  render_views

  let_it_be(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:report) { Fabricate(:report) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET #index' do
    it 'returns http success with no filters' do
      specified = Fabricate(:report, action_taken_at: nil)
      Fabricate(:report, action_taken_at: Time.now.utc)

      get :index

      reports = assigns(:reports).to_a
      expect(reports.size).to eq 1
      expect(reports[0]).to eq specified
      expect(response).to have_http_status(200)
    end

    it 'returns http success with resolved filter' do
      specified = Fabricate(:report, action_taken_at: Time.now.utc)
      Fabricate(:report, action_taken_at: nil)

      get :index, params: { resolved: '1' }

      reports = assigns(:reports).to_a
      expect(reports.size).to eq 1
      expect(reports[0]).to eq specified

      expect(response).to have_http_status(200)
    end
  end

  describe 'GET #show' do
    it 'renders report' do
      get :show, params: { id: report }

      expect(assigns(:report)).to eq report
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #resolve' do
    it 'resolves the report' do
      put :resolve, params: { id: report }
      expect(response).to redirect_to(admin_reports_path)
      report.reload
      expect(report.action_taken_by_account).to eq user.account
      expect(report.action_taken?).to be true
      expect(last_action_log.target).to eq(report)
    end
  end

  describe 'POST #reopen' do
    it 'reopens the report' do
      put :reopen, params: { id: report }
      expect(response).to redirect_to(admin_report_path(report))
      report.reload
      expect(report.action_taken_by_account).to be_nil
      expect(report.action_taken?).to be false
      expect(last_action_log.target).to eq(report)
    end
  end

  describe 'POST #assign_to_self' do
    it 'reopens the report' do
      put :assign_to_self, params: { id: report }
      expect(response).to redirect_to(admin_report_path(report))
      report.reload
      expect(report.assigned_account).to eq user.account
      expect(last_action_log.target).to eq(report)
    end
  end

  describe 'POST #unassign' do
    it 'reopens the report' do
      put :unassign, params: { id: report }
      expect(response).to redirect_to(admin_report_path(report))
      report.reload
      expect(report.assigned_account).to be_nil
      expect(last_action_log.target).to eq(report)
    end
  end

  private

  def last_action_log
    Admin::ActionLog.last
  end
end