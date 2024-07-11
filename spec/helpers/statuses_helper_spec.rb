# frozen_string_literal: true

require 'rails_helper'

describe StatusesHelper do
  describe 'status_text_summary' do
    context 'with blank text' do
      let(:status) { Status.new(spoiler_text: '') }

      it 'returns immediately with nil' do
        result = helper.status_text_summary(status)
        expect(result).to be_nil
      end
    end

    context 'with present text' do
      let(:status) { Status.new(spoiler_text: 'SPOILERS!!!') }

      it 'returns the content warning' do
        result = helper.status_text_summary(status)
        expect(result).to eq(I18n.t('statuses.content_warning', warning: 'SPOILERS!!!'))
      end
    end
  end

  def status_text_summary(status)
    return if status.spoiler_text.blank?

    I18n.t('statuses.content_warning', warning: status.spoiler_text)
  end

  describe 'fa_visibility_icon' do
    let_it_be(:public_status) { Status.new(visibility: 'public') }
    let_it_be(:unlisted_status) { Status.new(visibility: 'unlisted') }
    let_it_be(:private_status) { Status.new(visibility: 'private') }
    let_it_be(:direct_status) { Status.new(visibility: 'direct') }

    it 'returns the correct fa icon for public status' do
      expect(helper.fa_visibility_icon(public_status)).to match('fa-globe')
    end

    it 'returns the correct fa icon for unlisted status' do
      expect(helper.fa_visibility_icon(unlisted_status)).to match('fa-unlock')
    end

    it 'returns the correct fa icon for private status' do
      expect(helper.fa_visibility_icon(private_status)).to match('fa-lock')
    end

    it 'returns the correct fa icon for direct status' do
      expect(helper.fa_visibility_icon(direct_status)).to match('fa-at')
    end
  end

  describe '#stream_link_target' do
    it 'returns nil if it is not an embedded view' do
      set_not_embedded_view

      expect(helper.stream_link_target).to be_nil
    end

    it 'returns _blank if it is an embedded view' do
      set_embedded_view

      expect(helper.stream_link_target).to eq '_blank'
    end
  end

  def set_not_embedded_view
    params[:controller] = "not_#{StatusesHelper::EMBEDDED_CONTROLLER}"
    params[:action] = "not_#{StatusesHelper::EMBEDDED_ACTION}"
  end

  def set_embedded_view
    params[:controller] = StatusesHelper::EMBEDDED_CONTROLLER
    params[:action] = StatusesHelper::EMBEDDED_ACTION
  end
end