# frozen_string_literal: true

require 'simple_command'
require_relative '../../strategies/goggles_db/calculators/factory'

module GogglesDb
  #
  # = Score calculator command.
  #
  #   - version:  7-0.3.36
  #   - author:   Steve A.
  #   - build:    20211102
  #
  # Returns a dedicated calculator score strategy (depending on parameters) that:
  #
  # - retrieves & uses the associated StandardTiming if available;
  # - enables computing the result score for a timing;
  # - enables to reverse-computing the target timing for a desired result score.
  #
  # StandardTiming values for the specified Season are (usually) required in order for this
  # to function properly.
  #
  # (@see Calculators::BaseStrategy for more info)
  #
  class CmdSelectScoreCalculator
    prepend SimpleCommand

    attr_reader :strategy

    # Creates a new command object given the parameters.
    # Each parameter must be a valid instance of the corresponding named class (season: GogglesDb::Season,
    # and so on...)
    # Will raise ArgumentError if the constructor parameter aren't enough to build the strategy object.
    #
    # == Options:
    # - <tt>:pool_type</tt>: a valid instance of <tt>GogglesDb::PoolType</tt> (required).
    # - <tt>:event_type</tt>: a valid instance of <tt>GogglesDb::EventType</tt> (required).
    #
    # - <tt>:badge</tt>:
    #   a valid instance of <tt>GogglesDb::Badge</tt> (optional); can be +nil+ if all the other parameters
    #   are given (season, category_type, gender_type & pool_type).
    #
    # - <tt>:season</tt>: a valid instance of <tt>GogglesDb::Season</tt> (optional); can be +nil+ only if +badge+ is present.
    # - <tt>:gender_type</tt>: a valid instance of <tt>GogglesDb::GenderType</tt> (optional); can be +nil+ only if +badge+ is present.
    # - <tt>:category_type</tt>: a valid instance of <tt>GogglesDb::CategoryType</tt> (optional); can be +nil+ only if +badge+ is present.
    #
    # Either the badge or the season are always needed in order to get a valid SeasonType. Gender & category
    # can be derived from the badge directly.
    #
    # When all parameters are present, the named key takes precendence over the derived value
    # (i.e., when both season & badge are given, the first will be used and badge.season will not).
    #
    # == Supported +SeasonType+s
    #
    # - mas_fin || mas_fina || mas_len => Calculators::FINScore
    #
    def initialize(options = {})
      @pool_type = options[:pool_type]
      @event_type = options[:event_type]

      @badge = options[:badge]
      @season = options[:season]
      @gender_type = options[:gender_type]
      @category_type = options[:category_type]
    end

    # Sets:
    # - #strategy: the proper score calculator strategy given the constructor parameters.
    #
    # Always returns itself. Check #success? or #errors.empty? for detecting the outcome.
    #
    def call
      return unless internal_members_valid?

      @strategy = Calculators::Factory.for(
        pool_type: @pool_type,
        event_type: @event_type,
        badge: @badge,
        season: @season,
        gender_type: @gender_type,
        category_type: @category_type
      )
    end
    #-- --------------------------------------------------------------------------
    #++

    private

    # Checks validity of the constructor parameters; returns +false+ in case of error.
    def internal_members_valid?
      return true if @pool_type.instance_of?(GogglesDb::PoolType) &&
                     @event_type.instance_of?(GogglesDb::EventType) &&
                     (
                       @badge.instance_of?(GogglesDb::Badge) ||
                       (@season.instance_of?(GogglesDb::Season) &&
                        @gender_type.instance_of?(GogglesDb::GenderType) &&
                        @category_type.instance_of?(GogglesDb::CategoryType))
                     )

      errors.add(:msg, 'Invalid or missing constructor parameters')
      false
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
