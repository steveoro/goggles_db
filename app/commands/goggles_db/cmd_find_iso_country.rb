# frozen_string_literal: true

require 'simple_command'
require 'countries'

module GogglesDb
  #
  # = "Find ISO3166 Country" command
  #
  #   - file vers.: 0.4.01
  #   - author....: Steve A.
  #
  # Uses the countries gem (https://github.com/hexorx/countries) to seek for a matching
  # ISO3166 Country definition, given either (FIFO: whatever matches first in the
  # specified precedence):
  #
  # 1. its official name;
  # 2. its unofficial name;
  # 3. its 'alpha2' or 'alpha3' country code.
  #
  # Returns the corresponding ISO3166::Country instance, or +nil+ when not found.
  #
  #                                      - o -
  #
  # == ISO3166::Country & usage examples:
  #
  #   > c = GogglesDb::CmdFindIsoCountry.call('United States', 'USA').result
  #    => #<ISO3166::Country:0x000056454c7d34e8 @country_data_or_code="US", [...]
  #
  # (Same result as: ISO3166::Country.new('USA'))
  #
  #   > c.subdivisions["OH"]
  #    => #<struct ISO3166::Subdivision name="Ohio", code=nil, unofficial_names="Ohio", geo={"latitude"=> [...]
  #
  #   > c = GogglesDb::CmdFindIsoCountry.call('Italy', 'ITA').result
  #    => #<ISO3166::Country:0x000056454cd33910 @country_data_or_code="IT", [...]
  #
  # (Same result as: ISO3166::Country.new('ITA'))
  #
  #   > c.name
  #    => "Italy"
  #
  #   > c.alpha2
  #    => "IT"
  #
  #   > c.address_format
  #    => "{{recipient}}\n{{street}}\n{{postalcode}} {{city}} {{region_short}}\n{{country}}"
  #
  #   > c.translations # (Will include just the locales set in the initializer)
  #    => {"en"=>"Italy", "it"=>"Italia"}
  #
  #   > re = c.subdivisions['RE']
  #    => #<struct ISO3166::Subdivision name="Reggio Emilia", code=nil,
  #        unofficial_names="Reggio Emilia", geo={"latitude"=>44.6989932, [...]
  #
  #   > re.name
  #    => "Reggio Emilia"
  #
  class CmdFindIsoCountry
    prepend SimpleCommand

    # Creates a new command object given the parameters for the search.
    def initialize(country_name, country_code)
      @country_name = country_name
      @country_code = country_code
    end

    # Returns the corresponding ISO3166::Country instance when found.
    # Otherwise, sets #result to +nil+ and logs just the country name into the #errors hash.
    # Returns always itself.
    def call
      alpha_length = @country_code && @country_code.length < 3 ? 2 : 3
      coutry_code_alpha_method = "find_country_by_alpha#{alpha_length}"

      result = ISO3166::Country.find_country_by_iso_short_name(@country_name) ||
               ISO3166::Country.find_country_by_unofficial_names(@country_name) ||
               ISO3166::Country.send(coutry_code_alpha_method, @country_code)

      errors.add(:name, @country_name) if result.nil?
      result
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
