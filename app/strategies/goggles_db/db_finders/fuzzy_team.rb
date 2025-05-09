# frozen_string_literal: true

module GogglesDb
  module DbFinders
    #
    # = FuzzyTeam finder strategy
    #
    #   - version:  7-0.8.00
    #   - author:   Steve A.
    #   - build:    20241223
    #
    class FuzzyTeam < BaseStrategy
      # Creates a new search strategy instance given the parameters.
      #
      # == Options:
      # - <tt>search_terms</tt>: a *required* +Hash+ of search terms having the
      #   form: <tt>{ column_name1 => "target value", ... }</tt>, with the column names as symbols;
      #
      #   Add a <tt>toggle_debug: true</tt> element in <tt>search_terms</tt> to enable
      #   the verbose search output on the console (default: false); this will be removed from
      #   the search terms.
      #
      # - <tt>bias</tt>: fuzzy search bias for a match (default: 0.74)
      #
      def initialize(search_terms = {}, _bias = 0.74)
        # Use a less restrictive bias (0.75 allows for just a partial name)
        super(GogglesDb::Team, search_terms, :for_name, 0.74)
      end
      #-- --------------------------------------------------------------------------
      #++

      # Returns a stripped-down, pure ASCII 7-bit version of the specified name/value,
      # removing also the most common words.
      def normalize_value(value)
        GogglesDb::Normalizers::CodedName.normalize(value.downcase)
      end
      #-- --------------------------------------------------------------------------
      #++
    end
  end
end
