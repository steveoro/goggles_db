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
    # `name` varchar(50) DEFAULT NULL,   => RESIZE, NOT NULL
    # `zip` varchar(6) DEFAULT NULL,     => should be auto filled from Countries gem
    # `area` varchar(50) DEFAULT NULL,   => NOT needed anymore
    # `country` varchar(50) DEFAULT NULL, => RESIZE, NOT NULL
    # `country_code` varchar(10) DEFAULT NULL, => RESIZE, NOT NULL
    # `created_at` datetime DEFAULT NULL,
    # `updated_at` datetime DEFAULT NULL,
    # `user_id` int(11) DEFAULT NULL, => USELESS
    # `area_type_id` int(11) DEFAULT NULL, => USELESS
    # NEEDED:
    # t.string "latitude"
    # t.string "longitude"

    # TODO: enforce presence on table too; expand country name size to max
    validates :name,         presence: { length: { within: 3..50 }, allow_nil: false }
    validates :country_code, presence: { length: { within: 1..3 }, allow_nil: false } # Actual max length: 10
    validates :country,      presence: { length: { within: 1..50 }, allow_nil: false }

    # == Country gem usage examples: ==
    # > c = ISO3166::Country.new('US')
    # > Cities.cities_in_country('US').select{ |city| city =~ /miami/ }.count
    # => 28
    # > Cities.cities_in_country('US').select{ |city| city =~ /miami/ }["miamiville"]
    # => #<Cities::City:0x0000000b0efeb0 @data={"city"=>"miamiville", "accentcity"=>"Miamiville", "region"=>"OH", [...]
    # > c.subdivisions["OH"]
    #  => #<struct ISO3166::Subdivision name="Ohio", code=nil, unofficial_names="Ohio", geo={"latitude"=> [...]

    #-- -----------------------------------------------------------------------
    #++
  end
end
