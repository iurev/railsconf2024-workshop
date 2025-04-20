# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vacuum::ApplicationsVacuum do
  subject { described_class.new }

  describe '#perform' do
    let_it_be(:app_with_token)  { Fabricate(:application, created_at: 1.month.ago) }
    let_it_be(:app_with_grant)  { Fabricate(:application, created_at: 1.month.ago) }
    let_it_be(:app_with_signup) { Fabricate(:application, created_at: 1.month.ago) }
    let_it_be(:app_with_owner)  { Fabricate(:application, created_at: 1.month.ago, owner: Fabricate(:user)) }
    let_it_be(:unused_app)      { Fabricate(:application, created_at: 1.month.ago) }
    let_it_be(:recent_app)      { Fabricate(:application, created_at: 1.hour.ago) }

    before_all do
      Fabricate(:access_token, application: app_with_token)
      Fabricate(:access_grant, application: app_with_grant)
      Fabricate(:user, created_by_application: app_with_signup)

      described_class.new.perform
    end

    it 'does not delete applications with valid access tokens' do
      expect { app_with_token.reload }.to_not raise_error
    end

    it 'does not delete applications with valid access grants' do
      expect { app_with_grant.reload }.to_not raise_error
    end

    it 'does not delete applications that were used to create users' do
      expect { app_with_signup.reload }.to_not raise_error
    end

    it 'does not delete owned applications' do
      expect { app_with_owner.reload }.to_not raise_error
    end

    it 'does not delete applications registered less than a day ago' do
      expect { recent_app.reload }.to_not raise_error
    end

    it 'deletes unused applications' do
      expect { unused_app.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end