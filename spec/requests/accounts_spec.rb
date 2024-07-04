# frozen_string_literal: true

require 'rails_helper'

describe 'Accounts show response' do
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:user) { Fabricate(:user) }
  let_it_be(:status) { Fabricate(:status, account: account) }
  let_it_be(:status_reply) { Fabricate(:status, account: account, thread: Fabricate(:status)) }
  let_it_be(:status_self_reply) { Fabricate(:status, account: account, thread: status) }
  let_it_be(:status_media) { Fabricate(:status, account: account) }
  let_it_be(:status_pinned) { Fabricate(:status, account: account) }
  let_it_be(:status_private) { Fabricate(:status, account: account, visibility: :private) }
  let_it_be(:status_direct) { Fabricate(:status, account: account, visibility: :direct) }
  let_it_be(:status_reblog) { Fabricate(:status, account: account, reblog: Fabricate(:status)) }
  let_it_be(:tag) { Fabricate(:tag) }
  let_it_be(:status_tag) { Fabricate(:status, account: account) }

  before_all do
    status_media.media_attachments << Fabricate(:media_attachment, account: account, type: :image)
    account.pinned_statuses << status_pinned
    account.pinned_statuses << status_private
    status_tag.tags << tag
  end

  shared_examples 'common HTML response' do
    it 'returns a standard HTML response', :aggregate_failures do
      expect(response)
        .to have_http_status(200)
        .and render_template(:show)

      expect(response.headers['Link'].to_s).to include ActivityPub::TagManager.instance.uri_for(account)
    end
  end

  shared_examples 'cacheable response' do |options|
    it 'returns cacheable response' do
      expect(response).to have_http_status(200)
      expect(response.headers['Vary']).to include options[:expects_vary]
    end
  end

  context 'with an unapproved account' do
    before_all { account.user.update(approved: false) }

    it 'returns http not found for all formats' do
      %w(html json rss).each do |format|
        get short_account_path(username: account.username), as: format
        expect(response).to have_http_status(404)
      end
    end
  end

  context 'with a permanently suspended account' do
    before_all do
      account.suspend!
      account.deletion_request.destroy
    end

    it 'returns http gone for all formats' do
      %w(html json rss).each do |format|
        get short_account_path(username: account.username), as: format
        expect(response).to have_http_status(410)
      end
    end
  end

  context 'with a temporarily suspended account' do
    before_all { account.suspend! }

    it 'returns appropriate http response code for each format' do
      { html: 403, json: 200, rss: 403 }.each do |format, code|
        get short_account_path(username: account.username), as: format
        expect(response).to have_http_status(code)
      end
    end
  end

  describe 'GET to short username paths' do
    context 'with HTML' do
      let(:format) { 'html' }

      %w(short_account_path short_account_with_replies_path short_account_media_path).each do |path_helper|
        context "with #{path_helper}" do
          before { get send(path_helper, username: account.username), as: format }
          it_behaves_like 'common HTML response'
        end
      end

      context 'with tag' do
        before { get short_account_tag_path(username: account.username, tag: tag), as: format }
        it_behaves_like 'common HTML response'
      end
    end

    context 'with JSON' do
      let(:headers) { { 'ACCEPT' => 'application/json' } }

      context 'with a normal account in a JSON request' do
        before { get short_account_path(username: account.username), headers: headers }

        it 'returns a JSON version of the account', :aggregate_failures do
          expect(response)
            .to have_http_status(200)
            .and have_attributes(media_type: eq('application/activity+json'))

          expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
        end

        it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'
      end

      context 'when signed in' do
        before do
          sign_in(user)
          get short_account_path(username: account.username), headers: headers.merge({ 'Cookie' => '123' })
        end

        it 'returns a private JSON version of the account', :aggregate_failures do
          expect(response)
            .to have_http_status(200)
            .and have_attributes(media_type: eq('application/activity+json'))

          expect(response.headers['Cache-Control']).to include 'private'
          expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
        end
      end

      context 'with signature' do
        let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com') }

        before do
          get short_account_path(username: account.username), headers: headers, sign_with: remote_account
        end

        it 'returns a JSON version of the account', :aggregate_failures do
          expect(response)
            .to have_http_status(200)
            .and have_attributes(media_type: eq('application/activity+json'))

          expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
        end

        it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'
      end
    end

    context 'with RSS' do
      let(:format) { 'rss' }

      shared_examples 'RSS response' do |path_helper, included_statuses, excluded_statuses|
        before { get send(path_helper, username: account.username, format: format) }

        it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'

        it 'responds with correct statuses', :aggregate_failures do
          expect(response).to have_http_status(200)
          included_statuses.each { |s| expect(response.body).to include(status_tag_for(s)) }
          excluded_statuses.each { |s| expect(response.body).not_to include(status_tag_for(s)) }
        end
      end

      it_behaves_like 'RSS response', :short_account_path,
                      [:status_media, :status_self_reply, :status],
                      [:status_direct, :status_private, :status_reblog, :status_reply]

      it_behaves_like 'RSS response', :short_account_with_replies_path,
                      [:status_media, :status_reply, :status_self_reply, :status],
                      [:status_direct, :status_private, :status_reblog]

      it_behaves_like 'RSS response', :short_account_media_path,
                      [:status_media],
                      [:status_direct, :status_private, :status_reblog, :status_reply, :status_self_reply, :status]

      context 'with tag' do
        before do
          get short_account_tag_path(username: account.username, tag: tag, format: format)
        end

        it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'

        it 'responds with correct statuses', :aggregate_failures do
          expect(response).to have_http_status(200)
          expect(response.body).to include(status_tag_for(status_tag))
          [:status_direct, :status_media, :status_private, :status_reblog, :status_reply, :status_self_reply, :status].each do |s|
            expect(response.body).not_to include(status_tag_for(send(s)))
          end
        end
      end
    end
  end

  def status_tag_for(status)
    ActivityPub::TagManager.instance.url_for(status)
  end
end