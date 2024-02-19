# frozen_string_literal: true

module GogglesDb
  #
  # = "ISO3166 Region" list finder
  #
  #   - file vers.: 1.00
  #   - author....: Steve A.
  #   - build.....: 20201214
  #
  # Assumes the existence of a "regions-COUNTRY_ALPHA2_CODE.json" file stored in 'db/data'.
  # The regions data format must be:
  #
  #      { "ISO-3166-2_code 1" => "ISO region name 1 in native language", "code2" => "name2", ... }
  #
  # Item at key index 0 is assumed to be reserved for unknowns or uncertainty.
  # Use the "region" field value reported by the Cities gem to have a valid index for the #fetch.
  #
  #
  # === Example:
  #
  #   > iso_regions = GogglesDb::IsoRegionList.new('IT')
  #    => <GogglesDb::IsoRegionList ...>
  #
  #   > iso_regions.fetch(0)
  #    => "?"
  #
  #   > iso_regions.fetch(5)
  #    => "Emilia-Romagna"
  #
  class IsoRegionList
    # Creates a new object for the specified alpha-2 country.
    def initialize(country_code = 'IT')
      json_contents = File.read(GogglesDb::Engine.root.join('db', 'data', "regions-#{country_code.upcase}.json"))
      @regions = JSON.parse(json_contents)
    rescue Errno::ENOENT, JSON::ParserError
      @regions = { '00' => '?' }
    end

    # Returns the official Region/Subdivision name according to the ISO 3166-2 list for the
    # Country specified in the initializer.
    #
    # Returns "?" (unknown, stored at index zero) for invalid indexes.
    #
    def fetch(index)
      @regions[
        @regions.keys.fetch(index.to_i, @regions.keys.first)
      ]
    end
  end
end
