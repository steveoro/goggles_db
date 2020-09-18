# frozen_string_literal: true

module GogglesDb
  #
  # = Team model
  #
  #   - version:  7.000
  #   - author:   Steve A.
  #
  class City < ApplicationRecord
    self.table_name = 'cities'

    # TODO: edit structure
    # `id` int(11) NOT NULL AUTO_INCREMENT,
    # `lock_version` int(11) DEFAULT 0,
    # `name` varchar(50) DEFAULT NULL,
    # `zip` varchar(6) DEFAULT NULL,
    # `area` varchar(50) DEFAULT NULL,
    # `country` varchar(50) DEFAULT NULL,
    # `country_code` varchar(10) DEFAULT NULL,
    # `created_at` datetime DEFAULT NULL,
    # `updated_at` datetime DEFAULT NULL,
    # `user_id` int(11) DEFAULT NULL, => USELESS
    # `area_type_id` int(11) DEFAULT NULL, => USELESS
    # NEEDED:
    # t.string "latitude"
    # t.string "longitude"

    validates :country_code, presence: { length: { within: 1..3 }, allow_nil: false } # Actual max length: 10
    validates :country,      presence: { length: { within: 1..50 }, allow_nil: false }
    validates :name,         presence: { length: { within: 3..254 }, allow_nil: false }
    #-- -----------------------------------------------------------------------
    #++
  end
end
