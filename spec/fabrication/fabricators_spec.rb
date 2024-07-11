# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/fabrication/}) do |metadata|
    metadata[:type] = :fabrication
  end
end

RSpec.describe "Fabricators", type: :fabrication do
  before(:all) do
    Fabrication.manager.load_definitions if Fabrication.manager.empty?
  end

  Fabrication.manager.schematics.map(&:first).each do |factory_name|
    describe "The #{factory_name} factory" do
      it 'is able to create valid records' do
        records = Fabricate.times(2, factory_name)
        expect(records).to all(be_valid)
      end
    end
  end
end