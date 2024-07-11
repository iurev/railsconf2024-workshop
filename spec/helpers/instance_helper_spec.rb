# frozen_string_literal: true

require 'rails_helper'

describe InstanceHelper do
  let_it_be(:setting) { Setting.new }

  describe 'site_title' do
    it 'Uses the Setting.site_title value when it exists' do
      setting.site_title = 'New site title'
      allow(Setting).to receive(:site_title).and_return(setting.site_title)

      expect(helper.site_title).to eq 'New site title'
    end
  end

  describe 'site_hostname' do
    around do |example|
      before = Rails.configuration.x.local_domain
      example.run
      Rails.configuration.x.local_domain = before
    end

    it 'returns the local domain value' do
      Rails.configuration.x.local_domain = 'example.com'

      expect(helper.site_hostname).to eq 'example.com'
    end
  end
end