# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_timing_manageable_examples'
require 'wrappers/timing'

# Dummy class holder for the fields used by the module
class DummyTimingManageableIncludee
  attr_accessor :hundredths, :seconds, :minutes

  def initialize(hundredths = 0, seconds = 0, minutes = 0)
    @hundredths = hundredths
    @seconds = seconds
    @minutes = minutes
  end

  include TimingManageable
end
#-- ------------------------------------------------------------------------
#++

describe DummyTimingManageableIncludee do
  let(:hundredths) { ((rand * 100) % 99).to_i }
  let(:seconds) { ((rand * 100) % 59).to_i }
  let(:minutes) { ((rand * 100) % 59).to_i }
  let(:fixture_row) { DummyTimingManageableIncludee.new(hundredths, seconds, minutes) }

  it 'is a DummyTimingManageableIncludee' do
    expect(fixture_row).to be_a(DummyTimingManageableIncludee)
  end

  it_behaves_like 'TimingManageable'
end
