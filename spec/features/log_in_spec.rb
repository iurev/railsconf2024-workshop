# frozen_string_literal: true

require 'rails_helper'

describe 'Log in' do
  include ProfileStories

  subject { page }

  let_it_be(:email)    { 'test@example.com' }
  let_it_be(:password) { 'password' }

  before do
    as_a_registered_user
    visit new_user_session_path
  end

  it 'A valid email and password user is able to log in' do
    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_on I18n.t('auth.login')

    expect(subject).to have_css('div.app-holder')
  end

  it 'A invalid email and password user is not able to log in' do
    fill_in 'user_email', with: 'invalid_email'
    fill_in 'user_password', with: 'invalid_password'
    click_on I18n.t('auth.login')

    expect(subject).to have_css('.flash-message', text: failure_message('invalid'))
  end

  context 'when confirmed at is nil' do
    before do
      User.last.update(confirmed_at: nil)
      visit new_user_session_path
    end

    it 'A unconfirmed user is able to log in' do
      fill_in 'user_email', with: email
      fill_in 'user_password', with: password
      click_on I18n.t('auth.login')

      expect(subject).to have_css('div.admin-wrapper')
    end
  end

  def failure_message(message)
    keys = User.authentication_keys.map { |key| User.human_attribute_name(key) }
    I18n.t("devise.failure.#{message}", authentication_keys: keys.join('support.array.words_connector'))
  end
end