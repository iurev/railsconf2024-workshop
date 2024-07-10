# frozen_string_literal: true

require 'rails_helper'

describe 'Admin::Accounts' do
  let_it_be(:current_user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }
  let_it_be(:unapproved_user_account) { Fabricate(:account) }
  let_it_be(:approved_user_account) { Fabricate(:account) }

  before(:all) do
    unapproved_user_account.user.update(approved: false)
    approved_user_account.user.update(approved: true)
  end

  before do
    sign_in current_user
    visit admin_accounts_path
  end

  describe 'Performing batch updates' do
    context 'without selecting any accounts' do
      it 'displays a notice about account selection' do
        click_on button_for_suspend

        expect(page).to have_content(selection_error_text)
      end
    end

    context 'with action of `suspend`' do
      it 'suspends the account' do
        batch_checkbox_for(approved_user_account).check

        click_on button_for_suspend

        expect(approved_user_account.reload).to be_suspended
      end
    end

    context 'with action of `approve`' do
      it 'approves the account user' do
        batch_checkbox_for(unapproved_user_account).check

        click_on button_for_approve

        expect(unapproved_user_account.reload.user).to be_approved
      end
    end

    context 'with action of `reject`' do
      it 'rejects and removes the account' do
        batch_checkbox_for(unapproved_user_account).check

        click_on button_for_reject

        expect { unapproved_user_account.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    def button_for_suspend
      I18n.t('admin.accounts.perform_full_suspension')
    end

    def button_for_approve
      I18n.t('admin.accounts.approve')
    end

    def button_for_reject
      I18n.t('admin.accounts.reject')
    end

    def selection_error_text
      I18n.t('admin.accounts.no_account_selected')
    end

    def batch_checkbox_for(account)
      find("#form_account_batch_account_ids_#{account.id}")
    end
  end
end