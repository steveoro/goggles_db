# frozen_string_literal: true

require 'simple_command'
require 'cities'
require 'fuzzystringmatch'

module GogglesDb
  #
  # = "Find ISO3166 Cities" command
  #   - version:  7-0.5.01
  #   - author....: Steve A.
  #
  # === Dependencies:
  #
  # - 'cities' (https://github.com/joecorcoran/cities), used as source of "standard" cities definitions
  #
  # - 'fuzzy-string-match' (https://github.com/kiyoka/fuzzy-string-match), for computing the Jaro-Winkler text
  #   distance between candidates (see https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance)
  #
  # === Returns
  #
  # - result: best-fit or corresponding Cities::City instance among the matches; +nil+ when not found.
  #
  # - matches: Array of Struct/OpenStruct instances, sorted by weights in descending order, having structure:
  #            [
  #              <OpenStruct 1 candidate=Cities::City 1, weight=1.0>,
  #              <OpenStruct 2 candidate=Cities::City 2, weight=0.9>,
  #              ...
  #            ]
  #                                  - o -
  #
  # === Cities & Cities::City usage examples:
  #
  # When searching for the city names, countries are identified by their ISO 3166-1 alpha-2 codes:
  #
  #   > Cities.cities_in_country('US').select{ |city| city =~ /miami/ }.count
  #    => 28
  #
  #   > Cities.cities_in_country('US').select{ |city| city =~ /miami/ }["miamiville"]
  #    => #<Cities::City @data={"city"=>"miamiville", "accentcity"=>"Miamiville", "region"=>"OH", [...]
  #
  # The #cities_in_country helper returns an Hash of Cities::City instances, keyed by the
  # city lowercase name:
  #
  #   > cities_hash = Cities.cities_in_country('IT')
  #   [...]
  #   > re = cities_hash["reggio nell'emilia"]
  #    => #<Cities::City @data={"city"=>"reggio nell'emilia",
  #        "accentcity"=>"Reggio nell'Emilia", "region"=>"05", "population"=>nil,
  #        "latitude"=>"44.716667", "longitude"=>"10.6"}>
  #
  #   > re.name
  #    => "Reggio nell'Emilia"
  #
  #   > re.latlong
  #    => [44.716667, 10.6]
  #
  # The 'cities' gem also acts as a 'countries' extension, adding the '#cities' method to any
  # instance of ISO3166::Country (returns the same Hash of Cities::City instances as #cities_in_country does).
  # So, alternatively:
  #
  #   > country = ISO3166::Country.new('IT')
  #   > re = country.cities \
  #                 .select { |key_name, _city| key_name =~ /reggio.*emilia/i } \
  #                 .values.last
  #    => #<Cities::City @data={"city"=>"reggio nell'emilia",
  #        "accentcity"=>"Reggio nell'Emilia", "region"=>"05", "population"=>nil,
  #        "latitude"=>"44.716667", "longitude"=>"10.6"}>
  #
  class CmdFindIsoCity
    prepend SimpleCommand

    attr_reader :matches, :iso_country

    # Creates a new command object given the parameters for the search.
    #
    # === Parameters:
    # - <tt>iso_country</tt>: a valid ISO3166::Country instance; use +nil+ to toggle the *search* mode ON;
    #   if search mode is ON, a list of most-probable countries will be used to search for the city name;
    #   the list uses an educated-guess of priorities of most common countries for the current domain.
    #
    # - <tt>city_name</tt>: the City name to be searched
    #
    # - <tt>toggle_debug</tt>: any non-nil value will toggle verbose output to the console with the sorting weights
    #
    def initialize(iso_country, city_name, toggle_debug = nil)
      @iso_country = iso_country
      @city_name = city_name
      @toggle_debug = toggle_debug
      @candidate_struct = Struct.new(:candidate, :weight)
      @matches = []
    end

    # Sets the result to the best corresponding Cities::City instance (when at least a candidate is found).
    # While searching, updates the #matches array with a list of possible alternative candidates, sorted in descending order.
    # Each candidate stored in #matches will be an hash <tt>Struct(:candidate, :weight)</tt>.
    #
    # If the "search mode" is enabled (by not setting the ISO country in the constructor), an opinionated
    # list of possible countries is scanned one by one, searching for the same city name.
    # The first country having a matching city will be considered a valid result. (So the priority in the search list
    # matters in this case.)
    #
    # When no matches at all are found, this sets #result to +nil+ and logs the requested city name into the #errors hash.
    # Always returns itself.
    def call
      iso_countries = @iso_country.instance_of?(ISO3166::Country) ? [@iso_country] : opinionated_country_search_list

      iso_countries.each do |iso_country|
        scan_iso_cities_for_candidates_matching(iso_country, prepare_tokenized_reg_expression)
        # Set the resulting country with the last one used:
        @iso_country = iso_country
        break if @matches.present?
      end

      errors.add(:name, @city_name) if @matches.empty?
      sort_matches
      @matches.first&.candidate
    end
    #-- --------------------------------------------------------------------------
    #++

    # Internal instance of the metric used to compute text distance
    METRIC = FuzzyStringMatch::JaroWinkler.create(:native)

    # Any text distance >= MATCH_BIAS will be considered viable as a match
    MATCH_BIAS = 0.98

    private

    # Returns the array of ISO3166::Country instances used for the "search mode".
    def opinionated_country_search_list
      [
        ISO3166::Country.new('IT'),
        ISO3166::Country.new('NL'),
        ISO3166::Country.find_country_by_iso_short_name('Sweden'),
        ISO3166::Country.find_country_by_iso_short_name('Austria'),
        ISO3166::Country.new('US'),
        ISO3166::Country.new('GB'),
        ISO3166::Country.new('CZ'),
        ISO3166::Country.new('RU'),
        ISO3166::Country.new('DK'),
        ISO3166::Country.new('DE'),
        ISO3166::Country.new('CH'),
        ISO3166::Country.new('ES'),
        ISO3166::Country.new('FR'),
        ISO3166::Country.new('BE'),
        ISO3166::Country.new('JP')
      ]
    end

    # Loops on the defined Cities names collecting a @matches list with the candidates and their
    # best weight if the weight reaches at least the MATCH_BIAS.
    # Updates directly the internal @matches list.
    #
    def scan_iso_cities_for_candidates_matching(iso_country, regexp)
      weight = 0.0
      iso_country.cities.each do |key_name, city|
        # Precedence to the Regexp match:
        regexp_match = key_name =~ regexp
        if regexp_match
          weight = 1.0
          @matches << @candidate_struct.new(city, weight)
          break
        end

        # Store candidates only if they seem to be a match:
        weight = compute_best_weight(key_name, city)
        @matches << @candidate_struct.new(city, weight) if weight >= MATCH_BIAS
      end
    end

    # Removes common conjunctions in names to build up a "tokenized" Regexp able to
    # find more easily at least a match from the list of "standardized" city names.
    #
    # (Note: currently supports only locale 'it' city names)
    def prepare_tokenized_reg_expression
      conjunction_it = %w[
        a al all alla alle allo agli
        d da dal dall dalla dalle dallo dagli
        de del dell delle della dello degli
        di in il con
        su sul sull sulla sulle sullo sugli
        per tra fra
        le li gli
        ne nel nell nella nelle nello negli
      ]

      # Remove "Saint" prefix and split into "most-valuable tokens":
      name_tokens = @city_name.gsub(/s(an|ant)?['.\b\s]/i, '')
                              .split(/[\s'.`]/).compact
                              .reject { |word| word.empty? || conjunction_it.include?(word.downcase) }
                              .map { |token| "\\b#{token}\\b" }
      # Enforce terminators at boundaries for single tokens:
      name_tokens[0] = "^#{name_tokens[0]}$" if name_tokens.count == 1

      Regexp.new(name_tokens.join('.*'), Regexp::IGNORECASE)
    end
    #-- --------------------------------------------------------------------------
    #++

    # Sorts the resulting @matches array according to the computed Jaro-Winkler text metric distance.
    #
    def sort_matches
      return if @matches.empty?

      # Sort in descending order:
      @matches.sort! { |a, b| b.weight <=> a.weight }
      return unless @toggle_debug

      # Output verbose debugging output:
      Rails.logger.debug { "\r\n\r\n[#{@city_name}]" }
      @matches.each_with_index { |obj, index| Rails.logger.debug "#{index}. #{obj.candidate.name} (#{obj.weight})" }
    end

    # Return computed weight between searched name and:
    # 1. current candidate name, if it's a suitable match
    # 2. pure stripped-down-to-ASCII key name otherwise
    #
    # This works on the assumption that the candidate names may have accented letters or foreign alphabets in it.
    #
    def compute_best_weight(current_key_name, current_city)
      # Check the distance between the searched name the candidate name:
      weight = METRIC.getDistance(current_city.name.downcase, @city_name.downcase)
      return weight if weight >= MATCH_BIAS

      # Check also the distance from the pure ASCII key_name in case the first one isn't a match:
      # (may happen due to many accented names)
      METRIC.getDistance(current_key_name, @city_name.downcase)
    end
  end
end
