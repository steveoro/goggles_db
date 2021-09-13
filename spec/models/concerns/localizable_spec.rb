# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_localizable_examples'

# Dummy class holder for the fields used by the module
class DummyLocalizableIncludee < GogglesDb::AbstractLookupEntity
  attr_accessor :code

  def self.table_name
    'heat_types' # (any valid sibling of AbstractLookupEntity will do)
  end

  include Localizable
end
#-- ------------------------------------------------------------------------
#++

describe DummyLocalizableIncludee do
  subject { described_class.new(code: 'any_code') }

  it_behaves_like 'Localizable'
end
