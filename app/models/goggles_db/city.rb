# frozen_string_literal: true

module GogglesDb
  #
  # = City model
  #   - version:  7-0.5.10
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

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Fulltext search by name or area with additional domain inclusion by using standard "LIKE"s
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      where(
        '(MATCH(cities.name, cities.area) AGAINST(?)) OR (cities.name LIKE ?) OR (cities.area LIKE ?)',
        name, like_query, like_query
      )
    }
    #-- ------------------------------------------------------------------------
    #++

    # Returns the tuple [iso_country, iso_city] by searching for matches in the internal ISO-normalized
    # database of Countries & Cities (country + cities gems).
    # Updates *each time* the internal memoized members <tt>#iso_country</tt> & <tt>#iso_city</tt>.
    # Returns an empty Array when not found.
    #
    # === Usage example:
    #
    # > iso_country, iso_city = city.to_iso
    #
    # === ISO-Country (main) fields:
    #
    # - iso_country.alpha2: Country code, 2 characters (upcase)
    # - iso_country.alpha3: Country code, 3 characters (upcase)
    #
    # - iso_country.translations: Hash of country name translations, keyed by locale code (string)
    # - iso_country.country_code: numeric Country code (as phone prefix, typically)
    # - iso_country.address_format: address format in use
    #   (Example for 'IT': "{{recipient}}\n{{street}}\n{{postalcode}} {{city}} {{region_short}}\n{{country}}")
    #
    # - iso_country.continent: Continent name
    # - iso_country.unofficial_names: array list of alternative, localized string names
    #
    # - iso_country.subdivisions['RE'] => sub-struct for region/subdivision ('RE', for example)
    #   returning 'name', 'geo', 'translations', ...
    #
    # - iso_country.subdivision_names_with_codes: array of arrays, with both name and alpha2-subdivision code:
    #   (Example: [["Agrigento", "AG"], ["Alessandria", "AL"], ["Ancona", "AN"], ...])
    #
    # === ISO-City (main) fields:
    #
    # - iso_city.name: standardized City name
    # - iso_city.latitude: string latitude coordinate
    # - iso_city.longitude: string longitude coordinate
    #
    # == Returns:
    # The <tt>[iso_country, iso_city]</tt> array resulting from the ISO finders call.
    #
    def to_iso
      if must_enforce_country
        call_finders_using_stored_data || call_finders_using_guesses
      else
        call_finders_using_guesses || call_finders_using_stored_data
      end

      [@iso_country, @iso_city]
    end
    #-- -----------------------------------------------------------------------
    #++

    # Using the current 'area' name column value, searches for the first match of the name
    # inside the ISO subdivision list.
    # Updates *each time* the internal memoized member <tt>#subdivision</tt> (with the whole resulting array).
    #
    # == Params:
    # - <tt>iso_country</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid ISO3166::Country otherwise.
    #
    # == Returns:
    # The [subdivision_code, subdivision_struct] array, if available; +nil+ otherwise.
    # - 'subdivision_code': alpha2 region/subdivision code
    # - 'subdivision_struct': ISO struct including 'name' & 'geo' fields
    def iso_subdivision(iso_country = nil)
      # Remove illegal chars from Regexp before checking:
      area_token = area.to_s.delete('?')
      chosen_country = iso_country || @iso_country
      @subdivision = chosen_country&.subdivisions&.find do |_iso_code, iso_struct|
        next if area_token.blank?

        iso_struct.name =~ Regexp.new(area_token, Regexp::IGNORECASE)
      end
    end

    # Retrieves either the currently set ISO name or the serialized value on the model.
    #
    # == Params:
    # - <tt>iso_city</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid Cities::City otherwise.
    # == Returns:
    # In FIFO in precendence: 1) ISO City name, 2) 'name' column value
    def iso_name(iso_city = nil)
      chosen_city = iso_city || @iso_city
      chosen_city&.name || name
    end

    # Retrieves either the currently set ISO latitude or the serialized value on the model.
    #
    # == Params:
    # - <tt>iso_city</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid Cities::City otherwise.
    # == Returns:
    # A stringified value, taken with FIFO in precendence: 1) ISO City latitude, 2) 'latitude' column value
    def iso_latitude(iso_city = nil)
      chosen_city = iso_city || @iso_city
      chosen_city&.latitude&.to_s || latitude
    end

    # Retrieves either the currently set ISO longitude or the serialized value on the model.
    #
    # == Params:
    # - <tt>iso_city</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid Cities::City otherwise.
    # == Returns:
    # A stringified value, taken with FIFO in precendence: 1) ISO City longitude, 2) 'longitude' column value
    def iso_longitude(iso_city = nil)
      chosen_city = iso_city || @iso_city
      chosen_city&.longitude&.to_s || longitude
    end

    # Returns the ISO Region name, if available (+nil+ otherwise).
    #
    # == Params:
    # - <tt>iso_city</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid Cities::City otherwise.
    #
    # - <tt>iso_country</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid ISO3166::Country otherwise.
    def iso_region(iso_city = nil, iso_country = nil)
      chosen_country = iso_country || @iso_country
      chosen_city = iso_city || @iso_city
      @region_list ||= GogglesDb::IsoRegionList.new(iso_country_code(chosen_country))
      @region_list.fetch(chosen_city&.region)
    end

    # Returns the localized ISO Country name or the serialized value on the model.
    #
    # == Params:
    # - <tt>iso_country</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid ISO3166::Country otherwise.
    #
    # - <tt>locale_override</tt> => a locale code override; defaults to the current locale.
    #
    # == Returns:
    # In FIFO in precendence: 1) translated ISO Country name, 2) 'country' column value
    def localized_country_name(iso_country = nil, locale_override = I18n.locale)
      chosen_country = iso_country || @iso_country
      valid_country = chosen_country&.translations&.fetch(locale_override.to_s, nil) || country
      # User the first informal naming for excessively long names:
      return chosen_country&.unofficial_names&.first if valid_country.length > 50

      valid_country
    end

    # Retrieves either the currently set ISO country code or the serialized value on the model.
    #
    # == Params:
    # - <tt>iso_country</tt> => when +nil+, uses the internal memoized value computed by #to_iso;
    #   a valid ISO3166::Country otherwise.
    #
    # == Returns:
    # In FIFO in precendence: 1) ISO Country code, 2) 'country_code' column value
    def iso_country_code(iso_country = nil)
      # Make sure the internal memoized members are set:
      to_iso if @iso_country.blank?

      chosen_country = iso_country || @iso_country
      chosen_country&.alpha2 || country_code
    end

    # Retrieves either the currently set ISO subdivision name or the serialized <tt>area</tt> value on the model.
    #
    # == Params:
    # - <tt>subdivision</tt> => when +nil+, uses the internal memoized value computed by <tt>#iso_subdivision</tt>;
    #   an array including the ISO3166::Country sub-division struct as *last* element otherwise.
    #
    # == Returns:
    # In FIFO in precendence: 1) ISO subdivision name 2) <tt>area</tt> column value
    def iso_area(subdivision = nil)
      # Make sure the internal memoized members are set:
      to_iso if @iso_country.blank?
      iso_subdivision(@iso_country) if @subdivision.blank?

      chosen_subdivision = subdivision || @subdivision
      chosen_subdivision&.last&.name || area
    end

    # Retrieves either the currently set ISO subdivision name or the serialized <tt>area</tt> value on the model.
    #
    # == Params:
    # - <tt>subdivision</tt> => when +nil+, uses the internal memoized value computed by <tt>#iso_subdivision</tt>;
    #   an array including the ISO3166::Country sub-division area code as *first* element otherwise.
    #
    # == Returns:
    # The ISO subdivision alpha-2 code if defined; nil otherwise
    def iso_area_code(subdivision = nil)
      # Make sure the internal memoized members are set:
      to_iso if @iso_country.blank?
      iso_subdivision(@iso_country) if @subdivision.blank?

      chosen_subdivision = subdivision || @subdivision
      chosen_subdivision&.first
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns this instance attributes Hash merged with its normalized ISO names
    #
    # == Params:
    # - <tt>locale_override<tt> => a locale code override; defaults to the current locale.
    def iso_attributes(locale_override = I18n.locale)
      # Make sure the internal memoized members are set:
      to_iso if @iso_city.blank? || @iso_country.blank?
      iso_subdivision(@iso_country) if @subdivision.blank?

      prepare_iso_attributes(@iso_city, @iso_country, @subdivision, locale_override)
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label
      ).merge(
        iso_attributes(locale)
      )
    end
    #-- -----------------------------------------------------------------------
    #++

    private

    # Returns the additional Hash of standardized attribute names and values
    #
    # == Params:
    # - <tt>iso_city</tt> => a valid Cities::City.
    # - <tt>iso_country</tt> => a valid ISO3166::Country;
    # - <tt>subdivision</tt> => an Array similar to the one returned by <tt>#iso_subdivision()</tt>;
    # - <tt>locale_override</tt> => a locale code override; defaults to the current locale.
    def prepare_iso_attributes(iso_city, iso_country, subdivision, locale_override)
      {
        'name' => iso_name(iso_city),
        'latitude' => iso_latitude(iso_city),
        'longitude' => iso_longitude(iso_city),
        'country' => localized_country_name(iso_country, locale_override),
        'country_code' => iso_country_code(iso_country),
        'region' => iso_region(iso_city, iso_country),
        'area_code' => iso_area_code(subdivision),
        'area' => iso_area(subdivision)
      }
    end

    # Internal check for the current @city to see if it falls among one of the peculiar cases, so that we can invert the priority in
    # the country-search to avoid data corruption.
    #
    # === Explanation
    # For instance, having Italy as a higher priority country over San Marino inside the fuzzy finder's list,
    # yields 'Marino' (IT) as a possible city match over 'San Marino' (SMR).
    # For the same reason, having the USA over the GB or Canada, for that matter, yields several false-positive differences
    # due to similar named cities found in countries with higher priority.
    # So, in these cases, we need to give priority back to the actual column value stored inside the DB (which may have been
    # previously manually fixed).
    #
    # == Returns
    # +true+ if the city falls inside one of the peculiar cases in which we must consider the country as "good"; +false+ otherwise.
    def must_enforce_country
      [
        # City name  /  Country name
        ['San Marino', 'San Marino'],
        ['London', 'United Kingdom'],
        %w[Montreal Canada]
        # (...Add here more peculiar cases as they pop-up...)
      ].any? { |city_name, city_country| name == city_name && country == city_country }
    end

    # Calls CmdFindIsoCity performing some educated guesses.
    # When the enforced ISO country is +nil+ (default), it will run the city finder in "full search mode".
    # (*PRIORITY 1*)
    #
    # == Params:
    # - <tt>forced_iso_country</tt> => a valid ISO3166::Country will be used as 'forced' country for the internal finder;
    #   when +nil+, the internal finder will try to guess the country as well (default).
    #
    # == Returns
    # The #success? boolean result of the city finder.
    # In the process, it sets both <tt>@iso_country</tt> & <tt>@iso_city</tt> internal members.
    #
    def call_finders_using_guesses(forced_iso_country = nil)
      city_finder = GogglesDb::CmdFindIsoCity.call(forced_iso_country, name)
      @iso_country = city_finder.iso_country
      @iso_city = city_finder.result
      city_finder.success?
    end

    # Calls CmdFindIsoCity searching for the country using the serialized stored column data.
    # This is less reliable when the data is already corrupted but works well with already normalized rows.
    # (*PRIORITY 2*)
    #
    # == Returns
    # The #success? boolean result of the city finder.
    # In the process, it sets both <tt>@iso_country</tt> & <tt>@iso_city</tt>.
    #
    def call_finders_using_stored_data
      country_finder = GogglesDb::CmdFindIsoCountry.call(country, country_code)
      city_finder = GogglesDb::CmdFindIsoCity.call(country_finder.result, name)
      @iso_country = country_finder.result
      @iso_city = city_finder.result
      city_finder.success?
    end
  end
end
