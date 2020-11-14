# frozen_string_literal: true

require 'simple_command'
require 'cities'
require 'fuzzystringmatch'
require 'ostruct'

module GogglesDb
  #
  # = "Find ISO3166 Cities" command
  #
  #   - file vers.: 1.07
  #   - author....: Steve A.
  #   - build.....: 20201114
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
  # - matches: Array of OpenStruct instances, sorted by weights in descending order, with structure:
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

    attr_reader :matches

    # Creates a new command object given the parameters for the search.
    #
    # === Parameters:
    # - iso_country: a valid ISO3166::Country instance
    # - city_name: the City name to be searched
    # - toggle_debug: any non-nil value will toggle verbose output to the console with the sorting weights
    #
    def initialize(iso_country, city_name, toggle_debug = nil)
      @iso_country = iso_country
      @city_name = city_name
      @toggle_debug = toggle_debug
      @matches = []
    end

    # Sets the result to the best corresponding Cities::City instance (when at least a candidate is found).
    # While searching, updates the #matches array with a list of possible alternative candidates, sorted in descending order.
    #
    # Otherwise, sets #result to +nil+ and logs just the requested city name into the #errors hash.
    # Always returns itself.
    def call
      unless @iso_country.instance_of?(ISO3166::Country)
        errors.add(:msg, 'Invalid iso_country parameter')
        return
      end

      regexp = prepare_tokenized_reg_expression

      @iso_country.cities.each do |key_name, city|
        # Precendence to the Regexp match:
        regexp_match = key_name =~ regexp
        if regexp_match
          @matches << OpenStruct.new(candidate: city, weight: 1.0)
          break
        end
        # Store other candidates only if they seem to be a match:
        weight = METRIC.getDistance(key_name.downcase, @city_name.downcase)
        @matches << OpenStruct.new(candidate: city, weight: weight) if weight >= MATCH_BIAS
      end

      errors.add(:name, @city_name) if @matches.empty?
      sort_matches
      @matches.first&.candidate
    end
    #-- --------------------------------------------------------------------------
    #++

    private

    # Internal instance of the metric used to compute text distance
    METRIC = FuzzyStringMatch::JaroWinkler.create(:native)

    # Any text distance >= MATCH_BIAS will be considered viable as a match
    MATCH_BIAS = 0.89

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
      puts "\r\n\r\n[#{@city_name}]"
      @matches.each_with_index { |obj, index| puts "#{index}. #{obj.candidate.name} (#{obj.weight})" }
    end
  end
end
