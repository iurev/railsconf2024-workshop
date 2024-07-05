# frozen_string_literal: true

require 'rails_helper'

describe 'statuses/show.html.haml', :without_verify_partial_doubles do
  let_it_be(:alice) { Fabricate(:account, username: 'alice', display_name: 'Alice') }
  let_it_be(:status) { Fabricate(:status, account: alice, text: 'Hello World') }
  let_it_be(:media_attachment) { Fabricate(:media_attachment, account: alice, status: status, type: :video) }

  before_all do
    InstancePresenter.any_instance.stubs(:site_title).returns('example site')
    InstancePresenter.any_instance.stubs(:site_hostname).returns('example.com')
  end

  before do
    allow(view).to receive_messages(api_oembed_url: '', full_asset_url: '//asset.host/image.svg', current_account: nil, single_user_mode?: false)
    allow(view).to receive(:local_time)
    allow(view).to receive(:local_time_ago)
    assign(:instance_presenter, InstancePresenter.new)
    assign(:status, status)
    assign(:account, alice)
    assign(:descendant_threads, [])
  end

  it 'has valid opengraph tags' do
    render

    expect(header_tags)
      .to match(/<meta content=".+" property="og:title">/)
      .and match(/<meta content="article" property="og:type">/)
      .and match(/<meta content=".+" property="og:image">/)
      .and match(%r{<meta content="http://.+" property="og:url">})
  end

  it 'has twitter player tag' do
    render

    expect(header_tags)
      .to match(%r{<meta content="http://.+/media/.+/player" property="twitter:player">})
      .and match(/<meta content="player" property="twitter:card">/)
  end

  def header_tags
    view.content_for(:header_tags)
  end
end