# frozen_string_literal: true

module GogglesDb
  module DbFinders
    #
    # = FuzzyCity finder strategy
    #
    #   - version:  7-0.3.53
    #   - author:   Steve A.
    #   - build:    20220526
    #
    class FuzzyCity < BaseStrategy
      # Creates a new search strategy instance given the parameters.
      #
      # While CmdFindIsoCity works on the in-memory ISO database list, this strategy works only
      # on actual, serialized, database rows.
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
        super(GogglesDb::City, search_terms, :for_name, 0.8)
      end
      #-- --------------------------------------------------------------------------
      #++

      # Returns a stripped-down, pure ASCII 7-bit version of the specified name/value,
      # removing also the most common words.
      def normalize_value(value)
        super(value).gsub(/\bdi\b|\bdal\b|\bne'?\b|\bnei\b|\bnel(l')?\b/i, '')
                    .gsub(/\s+/, ' ').strip
                    .downcase
      end
      #-- --------------------------------------------------------------------------
      #++
    end
  end
end
