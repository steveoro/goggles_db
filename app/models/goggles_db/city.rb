# frozen_string_literal: true

module GogglesDb
  #
  # = City model
  #
  #   - version:  7.044
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

    # Returns the tuple [iso_country, iso_city] by searching for matches in the internal ISO-normalized
    # database of Countries & Cities (country + cities gems).
    # Returns an empty Array when not found.
    #
    # === Usage example:
    #
    # > iso_country, iso_city = city.to_iso
    #
    # === ISO-Country (main) fields:
    # - iso_country.alpha2: Country code, 2 characters (upcase)
    # - iso_country.alpha3: Country code, 3 characters (upcase)
    # - iso_country.translations: Hash of country name translations, keyed by locale code (string)
    # - iso_country.country_code: numeric Country code (as phone prefix, typically)
    # - iso_country.address_format: address format in use
    #   (Example for 'IT': "{{recipient}}\n{{street}}\n{{postalcode}} {{city}} {{region_short}}\n{{country}}")
    # - iso_country.continent: Continent name
    # - iso_country.unofficial_names: array list of alternative, localized string names
    # - iso_country.subdivisions['RE'] => sub-struct for region/subdivision ('RE', for example)
    #   returning 'name', 'geo', 'translations', ...
    # - iso_country.subdivision_names_with_codes: array of arrays, with both name and alpha2-subdivision code:
    #   (Example: [["Agrigento", "AG"], ["Alessandria", "AL"], ["Ancona", "AN"], ...])
    #
    # === ISO-City (main) fields:
    # - iso_city.name: standardized City name
    # - iso_city.latitude: string latitude coordinate
    # - iso_city.longitude: string longitude coordinate
    #
    def to_iso
      country_finder = GogglesDb::CmdFindIsoCountry.call(country, country_code)
      city_finder = GogglesDb::CmdFindIsoCity.call(country_finder.result, name)
      [country_finder.result, city_finder.result]
    end
    #-- -----------------------------------------------------------------------
    #++

    # Using the current 'area' name column value, searches for the first match of the name
    # inside the ISO subdivision list.
    #
    # === Returns:
    # The [subdivision_code, subdivision_struct] tuple, if available; +nil+ otherwise.
    # - 'subdivision_code': alpha2 region/subdivision code
    # - 'subdivision_struct': ISO struct including 'name' & 'geo' fields
    def iso_subdivision(iso_country)
      iso_country&.subdivisions&.find do |_iso_code, iso_struct|
        # Remove illegal chars from Regexp before checking:
        iso_struct.name =~ Regexp.new(area.to_s.gsub('?', ''), Regexp::IGNORECASE)
      end
    end

    # Returns in FIFO in precendence: 1) ISO City name, 2) 'name' column value
    def iso_name(iso_city)
      iso_city&.name || name
    end

    # Returns in FIFO in precendence: 1) ISO City latitude, 2) 'latitude' column value
    def iso_latitude(iso_city)
      iso_city&.latitude.to_s || latitude
    end

    # Returns in FIFO in precendence: 1) ISO City longitude, 2) 'longitude' column value
    def iso_longitude(iso_city)
      iso_city&.longitude.to_s || longitude
    end

    # Returns in FIFO in precendence: 1) translated ISO Country name, 2) 'country' column value
    def localized_country_name(iso_country, locale_override = I18n.locale)
      iso_country&.translations&.fetch(locale_override.to_s, nil) || country
    end

    # Returns in FIFO in precendence: 1) ISO Country code, 2) 'country_code' column value
    def iso_country_code(iso_country)
      iso_country&.alpha2 || country_code
    end

    # Returns in FIFO in precendence: 1) ISO subdivision name 2) 'area' column value
    def iso_area(subdivision)
      subdivision&.last&.name || area
    end

    # Returns the ISO subdivision alpha-2 code if defined; nil otherwise
    def iso_area_code(subdivision)
      subdivision&.first
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns this instance attributes Hash merged with its normalized ISO names
    def iso_attributes(locale_override = I18n.locale)
      iso_country, iso_city = to_iso
      subdivision = iso_subdivision(iso_country)
      attributes.merge(
        prepare_iso_attributes(iso_city, iso_country, subdivision, locale_override)
      )
    end

    # Override: includes all iso_attributes.
    # Use :locale as option key (with supported locale value) to override translations.
    def to_json(options = nil)
      iso_attributes(options&.fetch(:locale, nil)).to_json(options)
    end
    #-- -----------------------------------------------------------------------
    #++

    private

    # Returns the additional Hash of standardized attribute names and values
    def prepare_iso_attributes(iso_city, iso_country, subdivision, locale_override)
      {
        'name' => iso_name(iso_city),
        'latitude' => iso_latitude(iso_city),
        'longitude' => iso_longitude(iso_city),
        'country' => localized_country_name(iso_country, locale_override),
        'country_code' => iso_country_code(iso_country),
        'area_code' => iso_area_code(subdivision),
        'area' => iso_area(subdivision)
      }
    end
  end
end
