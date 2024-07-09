# frozen_string_literal: true

require 'rails_helper'
require 'test_prof'

RSpec.describe BackupService do
  subject(:service_call) { described_class.new.call(backup) }
