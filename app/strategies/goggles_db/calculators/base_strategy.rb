# frozen_string_literal: true

module GogglesDb
  # Wraps all calculator strategies that can be plugged into <tt>CmdComputeResultScore</tt> by the
  # dedicated factory.
  #
  # The factory will choose & build which strategy has to be used by the command object
  # depending on the specified parameters.
  #
  module Calculators
    #
    # = BaseStrategy parent object
    #
    #   - version:  7-0.3.36
    #   - author:   Steve A.
    #   - build:    20211028
    #
    # Encapsulates the base interface for its siblings.
    #
    class BaseStrategy
      # Creates a new base strategy.
      # Will raise ArgumentError if the constructor parameter aren't enough to build the strategy object.
      #
      # == Options:
      # - <tt>:pool_type</tt>: a valid instance of <tt>GogglesDb::PoolType</tt> (required).
      # - <tt>:event_type</tt>: a valid instance of <tt>GogglesDb::EventType</tt> (required).
      # - <tt>:timing</tt>: a valid instance of <tt>Timing</tt> (required).
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
      def initialize(options = {})
        @pool_type = options[:pool_type]
        @event_type = options[:event_type]
        @badge = options[:badge]
        @season = options[:season] || options[:badge]&.season
        @category_type = options[:category_type] || options[:badge]&.category_type
        @gender_type = options[:gender_type] || options[:badge]&.gender_type
        check_internal_members
      end
      #-- --------------------------------------------------------------------------
      #++

      # Memoized value of the <tt>StandardTiming</tt> associated with the constructor parameters.
      # Returns a <tt>GogglesDb::StandardTiming</tt> instance or +nil+ when not found.
      def standard_timing
        @standard_timing ||= GogglesDb::StandardTiming.where(
          season_id: @season.id,
          pool_type_id: @pool_type.id,
          gender_type_id: @gender_type.id,
          category_type_id: @category_type.id,
          event_type_id: @event_type.id
        ).first
      end

      # Base score-compute method for this family of Strategies.
      #
      # == Parameters:
      # - <tt>timing</tt>: a valid <tt>Timing</tt> instance.
      # - <tt>standard_points</tt>: the base score for computing the result; default: 1000.00.
      # - <tt>precision</tt>: the floating point precision (the number of decimals); default: 2.
      #
      # == Returns:
      # Returns the floating number resulting score. Never +nil+: zero in case of errors.
      #
      # Typically, the result is <tt>1/standard_points</tt>th of distance from a pre-existing
      # standard timing result.
      #
      # When no <tt>GogglesDb::StandardTiming</tt> is found for the constructor parameters,
      # the resulting score is always the specified <tt>standard_points</tt> value.
      #
      def compute_for(timing, standard_points: 1000.0, precision: 2)
        return 0.0 unless timing.instance_of?(Timing) || (timing && !timing.to_hundredths.positive?)

        standard_timing_value = standard_timing&.to_timing&.to_hundredths || 0.0
        return standard_points.to_f.round(precision) unless standard_timing_value.positive?

        (standard_timing_value.to_f * standard_points / timing.to_hundredths.to_f).round(precision)
      end

      # Base reverse computation helper.
      # Computes the timing necessary to obtain a given score for the event, pool type, gender, category & season
      # specified with the constructor.
      #
      # The base fraction on which the timing hundredths of a second are multiplied is the default
      # value for <tt>standard_points</tt> (1000.0).
      #
      # == Parameters:
      # - <tt>target_score</tt>: the desired score for which the resulting timing is needed.
      #   Automatically rounded to 2 decimals of precision.
      #
      # == Returns:
      # A <tt>Timing</tt> instance representing the target timing for the desired score.
      #
      def timing_from(target_score)
        return Timing.new unless target_score.to_f.positive?

        standard_timing_value = standard_timing&.to_timing&.to_hundredths || 0.0
        return Timing.new unless standard_timing_value.positive?
        return standard_timing.to_timing if target_score.round(2).to_i == 1000

        Timing.new.from_hundredths((standard_timing_value.to_f * 1000.0 / target_score.to_f).to_i)
      end
      #-- --------------------------------------------------------------------------
      #++

      private

      # Checks the validity of the internal members; raises ArgumentError on failure.
      def check_internal_members
        return true if @season.instance_of?(GogglesDb::Season) &&
                       @gender_type.instance_of?(GogglesDb::GenderType) &&
                       @category_type.instance_of?(GogglesDb::CategoryType) &&
                       @pool_type.instance_of?(GogglesDb::PoolType) &&
                       @event_type.instance_of?(GogglesDb::EventType)

        raise(ArgumentError, 'Invalid constructor parameters')
      end
    end
  end
end
