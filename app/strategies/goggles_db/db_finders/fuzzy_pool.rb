# frozen_string_literal: true

module GogglesDb
  module DbFinders
    #
    # = FuzzyPool finder strategy
    #
    #   - version:  7-0.3.53
    #   - author:   Steve A.
    #   - build:    20220526
    #
    class FuzzyPool < BaseStrategy
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
      def initialize(search_terms = {})
        super(GogglesDb::SwimmingPool, search_terms, :for_name, DEFAULT_MATCH_BIAS)
      end
      #-- --------------------------------------------------------------------------
      #++

      # Returns a stripped-down, pure ASCII 7-bit version of the specified name/value,
      # removing also the most common words.
      def normalize_value(value)
        super(value).gsub(/\bpiscina\b|\bpool\b|\bclub\b|\bcomunale\b/i, '')
                    .gsub(/\s+/, ' ').strip
                    .downcase
      end
      #-- --------------------------------------------------------------------------
      #++
    end
  end
end