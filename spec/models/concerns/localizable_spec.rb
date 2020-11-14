# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_localizable_examples'

# Dummy class holder for the fields used by the module
class DummyLocalizableIncludee
  attr_accessor :code

  def initialize(code)
    @code = code
  end

  def self.table_name
    'any_subentity_name'
  end

  include Localizable
end
#-- ------------------------------------------------------------------------
#++

describe DummyLocalizableIncludee do
  subject { DummyLocalizableIncludee.new('any_code') }

  it_behaves_like 'Localizable'
end
