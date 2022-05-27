# frozen_string_literal: true

require 'simple_command'
require 'fuzzystringmatch'
require 'ostruct'

module GogglesDb
  #
  # = "Find Swimmers" command
  #
  #   - version:  7-0.3.53
  #   - author:   Steve A.
  #   - build:    20220524
  #
  # == Dependencies:
  #
  # - 'fuzzy-string-match' (https://github.com/kiyoka/fuzzy-string-match), for computing the Jaro-Winkler text
  #   distance between candidates (see https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance)
  #
  # == Returns
  #
  # - result: best-fit or corresponding database row instance among the matches; +nil+ when not found.
  #
  # - matches: Array of OpenStruct instances, sorted by weights in descending order, with structure:
  #            [
  #              <OpenStruct 1 candidate=[entity row 1], weight=1.0>,
  #              <OpenStruct 2 candidate=[entity row 2], weight=0.9>,
  #              ...
  #            ]
  #
  class CmdFindDbEntity
    prepend SimpleCommand

    attr_reader :matches

    # Creates a new finder command object given the parameters for the search.
    # Currently supported ActiveRecord models for the search strategy:
    # - GogglesDb::Swimmer
    # - GogglesDb::Team
    # - GogglesDb::SwimmingPool
    # - GogglesDb::Meeting
    # - GogglesDb::City (works only on stored rows, not on ISOCities or ISOCountries)
    #
    # == Params:
    # - <tt>model_klass</tt>: the target AR model.
    #
    # - <tt>search_terms</tt>: a *required* +Hash+ of search terms having the
    #   form: <tt>{ column_name1 => "target value", ... }</tt>, with the column names as symbols;
    #
    #   Add a <tt>toggle_debug: true</tt> element in <tt>search_terms</tt> to enable
    #   the verbose search output on the console (default: false); this will be removed from
    #   the search terms.
    #
    #
    # == Example usage:
    #
    #   > cmd = GogglesDb::CmdFindDbEntity.call(GogglesDb::Swimmer, complete_name: 'alloro')
    #   > cmd.successful?
    #   => true
    #   > cmd.result
    #   => #<GogglesDb::Swimmer id: 142, ...>
    #
    #   > cmd = GogglesDb::CmdFindDbEntity.call(GogglesDb::Team, name: 'o. ferrari')
    #   > cmd.successful?
    #   => true
    #   > cmd.result
    #   => #<GogglesDb::Team id: 1, ...>
    #
    def initialize(model_klass, search_terms = {})
      @search_terms = search_terms
      @finder = DbFinders::Factory.for(model_klass, search_terms)
      @matches = []
    end

    # Sets the result to the best corresponding GogglesDb::Swimmer instance (when at least a candidate is found).
    # While searching, updates the #matches array with a list of possible alternative candidates, sorted in descending order.
    #
    # Otherwise, sets #result to +nil+ and logs just the requested swimmer name into the #errors hash.
    # Always returns itself.
    def call
      @finder.scan_for_matches
      errors.add(@search_terms.keys.first, @search_terms.values.first) if @finder.matches.empty?
      @finder.sort_matches
      @matches = @finder.matches
      @finder.matches.first&.candidate
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
