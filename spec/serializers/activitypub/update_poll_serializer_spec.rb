# frozen_string_literal: true

require 'rails_helper'

describe ActivityPub::UpdatePollSerializer do
  subject { serialized_record_json(status, described_class, adapter: ActivityPub::Adapter) }

  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:poll)    { Fabricate(:poll, account: account) }
  let_it_be(:status)  { Fabricate(:status, account: account, poll: poll) }

  it 'has a Update type' do
    expect(subject['type']).to eql('Update')
  end

  it 'has an object with Question type' do
    expect(subject['object']['type']).to eql('Question')
  end

  it 'has the correct actor URI set' do
    expect(subject['actor']).to eql(ActivityPub::TagManager.instance.uri_for(account))
  end
end