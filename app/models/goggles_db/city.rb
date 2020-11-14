# frozen_string_literal: true

module GogglesDb
  #
  # = City model
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  # Check out:
  # - app/commands/goggles_db/cmd_find_iso_city.rb
  # - app/commands/goggles_db/cmd_find_iso_country.rb
  #
  class City < ApplicationRecord
    self.table_name = 'cities'

    validates :name,         presence: { length: { within: 3..50 }, allow_nil: false }
    validates :country_code, presence: { length: { within: 1..3 }, allow_nil: false } # Actual max length: 10
    validates :country,      presence: { length: { within: 1..50 }, allow_nil: true }
    validates :zip,          presence: { length: { within: 1..6 }, allow_nil: true }
    validates :area,         presence: { length: { within: 1..50 }, allow_nil: true }
    #-- -----------------------------------------------------------------------
    #++
  end
end
