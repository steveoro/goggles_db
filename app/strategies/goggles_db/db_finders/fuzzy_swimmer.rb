# frozen_string_literal: true

module GogglesDb
  module DbFinders
    #
    # = FuzzySwimmer finder strategy
    #
    #   - version:  7-0.3.53
    #   - author:   Steve A.
    #   - build:    20220526
    #
    class FuzzySwimmer < BaseStrategy
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
        # Use a less restrictive bias (0.8 allows for just a surname)
        super(GogglesDb::Swimmer, search_terms, :for_name, 0.8)
      end
      #-- --------------------------------------------------------------------------
      #++
    end
  end
end
