# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminMailer do
  let_it_be(:recipient) { Fabricate(:account) }

  before do
    recipient.user.update(locale: :en)
  end

  shared_examples 'common email expectations' do
    it 'renders the email' do
      expect(mail).to be_present
      expect(mail).to deliver_to(recipient.user_email)
      expect(mail).to deliver_from('notifications@localhost')
    end
  end

  describe '.new_report' do
    let_it_be(:sender) { Fabricate(:account, username: 'John') }
    let_it_be(:report) { Fabricate(:report, account: sender, target_account: recipient) }
    let(:mail) { described_class.with(recipient: recipient).new_report(report) }

    include_examples 'common email expectations'

    it 'has correct subject and body' do
      expect(mail).to have_subject("New report for cb6e6126.ngrok.io (##{report.id})")
      expect(mail).to have_body_text("#{recipient.username},\r\n\r\nJohn has reported #{recipient.username}\r\n\r\nView: https://cb6e6126.ngrok.io/admin/reports/#{report.id}\r\n")
    end
  end

  describe '.new_appeal' do
    let_it_be(:appeal) { Fabricate(:appeal) }
    let(:mail) { described_class.with(recipient: recipient).new_appeal(appeal) }

    include_examples 'common email expectations'

    it 'has correct subject and body' do
      expect(mail).to have_subject("#{appeal.account.username} is appealing a moderation decision on cb6e6126.ngrok.io")
      expect(mail).to have_body_text("#{appeal.account.username} is appealing a moderation decision by #{appeal.strike.account.username}")
    end
  end

  describe '.new_pending_account' do
    let_it_be(:user) { Fabricate(:user) }
    let(:mail) { described_class.with(recipient: recipient).new_pending_account(user) }

    include_examples 'common email expectations'

    it 'has correct subject and body' do
      expect(mail).to have_subject("New account up for review on cb6e6126.ngrok.io (#{user.account.username})")
      expect(mail).to have_body_text('The details of the new account are below. You can approve or reject this application.')
    end
  end

  describe '.new_trends' do
    let_it_be(:link) { Fabricate(:preview_card, trendable: true, language: 'en') }
    let_it_be(:status) { Fabricate(:status) }
    let_it_be(:tag) { Fabricate(:tag) }
    let(:mail) { described_class.with(recipient: recipient).new_trends([link], [tag], [status]) }

    before do
      PreviewCardTrend.create!(preview_card: link)
      StatusTrend.create!(status: status, account: Fabricate(:account))
    end

    include_examples 'common email expectations'

    it 'has correct subject and body' do
      expect(mail).to have_subject('New trends up for review on cb6e6126.ngrok.io')
      expect(mail).to have_body_text('The following items need a review before they can be displayed publicly')
      expect(mail).to have_body_text(ActivityPub::TagManager.instance.url_for(status))
      expect(mail).to have_body_text(link.title)
      expect(mail).to have_body_text(tag.display_name)
    end
  end

  describe '.new_software_updates' do
    let(:mail) { described_class.with(recipient: recipient).new_software_updates }

    include_examples 'common email expectations'

    it 'has correct subject and body' do
      expect(mail).to have_subject('New Mastodon versions are available for cb6e6126.ngrok.io!')
      expect(mail).to have_body_text('New Mastodon versions have been released, you may want to update!')
    end
  end

  describe '.new_critical_software_updates' do
    let(:mail) { described_class.with(recipient: recipient).new_critical_software_updates }

    include_examples 'common email expectations'

    it 'has correct subject and body' do
      expect(mail).to have_subject('Critical Mastodon updates are available for cb6e6126.ngrok.io!')
      expect(mail).to have_body_text('New critical versions of Mastodon have been released, you may want to update as soon as possible!')
      expect(mail).to have_header('Importance', 'high')
      expect(mail).to have_header('Priority', 'urgent')
      expect(mail).to have_header('X-Priority', '1')
    end
  end
end