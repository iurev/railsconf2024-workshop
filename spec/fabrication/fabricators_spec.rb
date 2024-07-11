# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Fabricators", :fabrication do
  before_all do
    Fabrication.manager.load_definitions if Fabrication.manager.empty?
  end

  let_it_be(:factory_names) { Fabrication.manager.schematics.map(&:first) }

  factory_names.each do |factory_name|
    it "is able to create valid records for #{factory_name}" do
      records = Fabricate.times(2, factory_name)
      expect(records).to all(be_valid)
    end
  end
end