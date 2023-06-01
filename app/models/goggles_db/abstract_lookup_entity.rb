# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Lookup Entity model
  #
  # Encapsulates common behavior for in-memory lookup entities.
  # Typical usage: short tables that store data that seldom needs any update.
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  class AbstractLookupEntity < ApplicationRecord
    self.abstract_class = true

    include Localizable

    validates :code, presence: { length: { within: 1..3 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }
    #-- -----------------------------------------------------------------------
    #++
  end
end
