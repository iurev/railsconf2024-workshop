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
  let_it_be(:remote_account) { Fabricate(:account, domain: 'example.com') }

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
    it 'sets appropriate cache headers' do
      expect(response.headers['Vary']).to include(options[:expects_vary])
    end
  end

  context 'with an unapproved account' do
    before_all { account.user.update(approved: false) }

    it 'returns http not found' do
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

    it 'returns http gone' do
      %w(html json rss).each do |format|
        get short_account_path(username: account.username), as: format
        expect(response).to have_http_status(410)
      end
    end
  end

  context 'with a temporarily suspended account' do
    before_all { account.suspend! }

    it 'returns appropriate http response code' do
      { html: 403, json: 200, rss: 403 }.each do |format, code|
        get short_account_path(username: account.username), as: format
        expect(response).to have_http_status(code)
      end
    end
  end

  describe 'GET to short username paths' do
    context 'with existing statuses' do
      context 'with HTML' do
        let(:format) { 'html' }

        %w(
          short_account_path
          short_account_with_replies_path
          short_account_media_path
        ).each do |path_helper|
          context "with #{path_helper}" do
            before do
              get public_send(path_helper, username: account.username), as: format
            end

            it_behaves_like 'common HTML response'
          end
        end

        context 'with tag' do
          before do
            get short_account_tag_path(username: account.username, tag: tag), as: format
          end

          it_behaves_like 'common HTML response'
        end
      end

      context 'with JSON' do
        let(:authorized_fetch_mode) { false }
        let(:headers) { { 'ACCEPT' => 'application/json' } }

        around do |example|
          ClimateControl.modify AUTHORIZED_FETCH: authorized_fetch_mode.to_s do
            example.run
          end
        end

        context 'with a normal account in a JSON request' do
          before do
            get short_account_path(username: account.username), headers: headers
          end

          it 'returns a JSON version of the account', :aggregate_failures do
            expect(response)
              .to have_http_status(200)
              .and have_attributes(
                media_type: eq('application/activity+json')
              )

            expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
          end

          it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'

          context 'with authorized fetch mode' do
            let(:authorized_fetch_mode) { true }

            it 'returns http unauthorized' do
              expect(response).to have_http_status(401)
            end
          end
        end

        context 'when signed in' do
          before do
            sign_in(user)
            get short_account_path(username: account.username), headers: headers.merge({ 'Cookie' => '123' })
          end

          it 'returns a private JSON version of the account', :aggregate_failures do
            expect(response)
              .to have_http_status(200)
              .and have_attributes(
                media_type: eq('application/activity+json')
              )

            expect(response.headers['Cache-Control']).to include 'private'

            expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
          end
        end

        context 'with signature' do
          before do
            get short_account_path(username: account.username), headers: headers, sign_with: remote_account
          end

          it 'returns a JSON version of the account', :aggregate_failures do
            expect(response)
              .to have_http_status(200)
              .and have_attributes(
                media_type: eq('application/activity+json')
              )

            expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
          end

          it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'

          context 'with authorized fetch mode' do
            let(:authorized_fetch_mode) { true }

            it 'returns a private signature JSON version of the account', :aggregate_failures do
              expect(response)
                .to have_http_status(200)
                .and have_attributes(
                  media_type: eq('application/activity+json')
                )

              expect(response.headers['Cache-Control']).to include 'private'
              expect(response.headers['Vary']).to include 'Signature'

              expect(body_as_json).to include(:id, :type, :preferredUsername, :inbox, :publicKey, :name, :summary)
            end
          end
        end
      end

      context 'with RSS' do
        let(:format) { 'rss' }

        shared_examples 'RSS response' do |options|
          it 'responds with correct statuses', :aggregate_failures do
            expect(response).to have_http_status(200)
            options[:includes].each do |status|
              expect(response.body).to include(status_tag_for(public_send(status)))
            end
            options[:excludes].each do |status|
              expect(response.body).to_not include(status_tag_for(public_send(status)))
            end
          end

          it_behaves_like 'cacheable response', expects_vary: 'Accept, Accept-Language, Cookie'
        end

        context 'with a normal account in an RSS request' do
          before do
            get short_account_path(username: account.username, format: format)
          end

          it_behaves_like 'RSS response', includes: [:status_media, :status_self_reply, :status], excludes: [:status_direct, :status_private, :status_reblog, :status_reply]
        end

        context 'with replies' do
          before do
            get short_account_with_replies_path(username: account.username, format: format)
          end

          it_behaves_like 'RSS response', includes: [:status_media, :status_reply, :status_self_reply, :status], excludes: [:status_direct, :status_private, :status_reblog]
        end

        context 'with media' do
          before do
            get short_account_media_path(username: account.username, format: format)
          end

          it_behaves_like 'RSS response', includes: [:status_media], excludes: [:status_direct, :status_private, :status_reblog, :status_reply, :status_self_reply, :status]
        end

        context 'with tag' do
          before do
            get short_account_tag_path(username: account.username, tag: tag, format: format)
          end

          it_behaves_like 'RSS response', includes: [:status_tag], excludes: [:status_direct, :status_media, :status_private, :status_reblog, :status_reply, :status_self_reply, :status]
        end
      end
    end
  end

  def status_tag_for(status)
    ActivityPub::TagManager.instance.url_for(status)
  end
end