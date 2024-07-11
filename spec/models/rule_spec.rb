# frozen_string_literal: true

require 'rails_helper'

describe Rule do
  describe 'scopes' do
    describe 'ordered' do
      let_it_be(:deleted_rule) { Fabricate(:rule, deleted_at: 10.days.ago) }
      let_it_be(:first_rule) { Fabricate(:rule, deleted_at: nil, priority: 1) }
      let_it_be(:last_rule) { Fabricate(:rule, deleted_at: nil, priority: 10) }

      it 'finds the correct records' do
        results = described_class.ordered

        expect(results).to eq([first_rule, last_rule])
      end
    end
  end
end