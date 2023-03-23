# frozen_string_literal: true

require 'singleton'

module GogglesDb
  module Normalizers
    #
    # = CityName
    #
    #   - version:  7-0.4.01
    #   - author:   Steve A.
    #   - build:    20220822
    #
    # City name, area & country normalizer.
    # Uses the ISO attributes to find a standardized name for all attributes (not just the city name).
    #
    # === WARNING:
    # City#to_iso delegates the finder strategy to CmdFindIsoCity, which relies on an opinionated
    # Country priority list. This means that if a Country has a "similar enough" (for the fuzzy-matcher
    # bias) named city, it will use that as first choice.
    #
    # So it may be possible that the result from the normalizer, if not verified, may corrupt
    # existing verified city names, areas & countries.
    # (For this reason, the related normalizer task has a "simulate" mode, which does not alter
    # the DB and just outputs the prospected updates.)
    #
    # Refactored from the original normalizer task.
    #
    class CityName
      attr_reader :iso_country, :iso_city

      # Creates a new instance of this strategy.
      #
      # == Params
      # - <tt>city</tt> => a valid GogglesDb::City instance
      # - <tt>verbose:</tt> => set this to +true+ to add standard output verbosity (used by the Rake task)
      #
      def initialize(city, verbose: false)
        raise(ArgumentError, 'Invalid parameter specified') unless city.is_a?(GogglesDb::City) && city.valid?

        @city = city
        @verbose = verbose
      end

      # Changes the specified instance values of the city, area, country and country code according to
      # what the ISO attributes report.
      #
      # This method doesn't save any changes made to the model as per usage contract. (See the normalizer task)
      #
      # == Returns:
      # the un-serialized instance with all the attributes "normalized" (according to what the ISO finder
      # reports).
      # The same (untouched) instance in case of errors (member values of <tt>#iso_country</tt> &
      # <tt>#iso_country</tt> may result +nil+ in this case).
      #
      # == Note:
      # Check <tt>city.has_changes_to_save?</tt> to check for actual changes and save them externally when
      # necessary.
      #
      def process
        @iso_country, @iso_city = @city.to_iso
        @iso_attributes = iso_attributes

        # Skip process if the country cannot be found:
        if @iso_country.nil?
          Rails.logger.debug { "'#{@city.name}' (ID: #{@city.id}) \033[1;33;31m× UNKNOWN COUNTRY ×\033[0m (#{@city.country})\r\n" } if @verbose
          return @city
        end

        if @iso_city.nil?
          Rails.logger.debug { "'#{@city.name}' (ID: #{@city.id}) \033[1;33;31m× UNKNOWN ×\033[0m\r\n" } if @verbose
        else
          change_city
        end
        # Return the normalized model row (unsaved):
        @city
      end
      #-- -----------------------------------------------------------------------
      #++

      # Allows to output a difference between a model column value and a corresponding ISO attribute value.
      # (Uses the internal set members, so it assumes the #process() method has already been called.)
      #
      # == Params:
      # - <tt>column_name</tt> => the string column name of the model;
      # - <tt>iso_attr_name</tt> => a corresponding ISO attribute name for the values comparison.
      #
      # == Returns:
      # Returns +true+ if the column name value differs from the corresponding ISO attribute value (equality match).
      # Returns +false+ if there are no string differences.
      #
      def output_if_differs?(column_name, iso_attr_name)
        iso_value = iso_attributes.fetch(iso_attr_name.to_s, '').to_s
        column_value = @city.send(column_name).to_s
        differs = iso_value != column_value
        # Output the difference (when verbose)
        if @verbose
          Rails.logger.debug do
            "        #{differs ? "\033[1;33;31m×\033[0m" : "\033[1;33;32m=\033[0m"} #{column_name}: " \
              "#{differs ? "#{column_value} != " : ''}#{iso_value}\r\n"
          end
        end
        differs
      end
      #-- -----------------------------------------------------------------------
      #++

      # Memoized Hash storing all ISO attributes
      def iso_attributes
        @iso_attributes ||= @city.iso_attributes
      end

      private

      # Updates the @city model attributes values with the corresponding ISO attribute values.
      def change_city
        Rails.logger.debug { "'#{@city.name}' (ID: #{@city.id}) => \033[1;33;32mFOUND\033[0m → #{@iso_city.name} (#{@iso_country.alpha2})\r\n" } if @verbose

        # "Normalize" the attributes with their corresponding ISO value:
        %w[name latitude longitude area country country_code].each do |attribute_name|
          output_if_differs?(attribute_name, attribute_name)
          @city.send("#{attribute_name}=", iso_attributes[attribute_name])
        end
      end
    end
  end
end
