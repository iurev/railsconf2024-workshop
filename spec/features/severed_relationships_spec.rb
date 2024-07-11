# frozen_string_literal: true

require 'rails_helper'

describe 'Severed relationships page' do
  include ProfileStories

  describe 'GET severed_relationships#index' do
    let_it_be(:event) { Fabricate(:relationship_severance_event) }
    let_it_be(:user) { Fabricate(:user) }
    let_it_be(:severed_relationships) do
      Fabricate.times(3, :severed_relationship, local_account: user.account, relationship_severance_event: event)
    end
    let_it_be(:account_event) do
      Fabricate(:account_relationship_severance_event, account: user.account, relationship_severance_event: event)
    end

    before do
      sign_in(user)
    end

    it 'returns http success' do
      visit severed_relationships_path

      expect(page).to have_title(I18n.t('settings.severed_relationships'))
      expect(page).to have_link(href: following_severed_relationship_path(AccountRelationshipSeveranceEvent.first, format: :csv))
    end
  end
end