# frozen_string_literal: true

require 'singleton'

module GogglesDb
  # Wraps all calculator strategies that can be plugged into <tt>CmdComputeResultScore</tt> by the
  # dedicated factory.
  #
  # The factory will choose & build which strategy has to be used by the command object
  # depending on the specified parameters.
  #
  module Calculators
    #
    # = Calculators singleton factory
    #
    #   - version:  7-0.3.36
    #   - author:   Steve A.
    #   - build:    20211028
    #
    # Allows to create a plug-in strategy object for computing a Season-specific
    # meeting score, according the specified parameters (swimmer, event & timing).
    #
    class Factory
      include Singleton

      # Returns a dedicated strategy instance depending on the specified Season.
      # It never returns +nil+.
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
      # == Supported +SeasonType+s
      #
      # - mas_fin || mas_fina || mas_len => Calculators::FINScore
      # - mas_csi  => Calculators::CSIScore
      # - mas_uisp => Calculators::UISPScore
      #
      # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      def self.for(options = {})
        season_type = options[:badge]&.season_type || options[:season]&.season_type
        raise(ArgumentError, 'Invalid parameters specified') unless options[:pool_type].instance_of?(GogglesDb::PoolType) &&
                                                                    options[:event_type].instance_of?(GogglesDb::EventType) &&
                                                                    season_type.instance_of?(GogglesDb::SeasonType)

        if season_type.mas_fin? || season_type.mas_fina? || season_type.mas_len?
          FINScore.new(
            pool_type: options[:pool_type], event_type: options[:event_type],
            badge: options[:badge],
            season: options[:season], gender_type: options[:gender_type], category_type: options[:category_type]
          )
        elsif season_type.mas_csi?
          CSIScore.new(
            pool_type: options[:pool_type], event_type: options[:event_type],
            badge: options[:badge],
            season: options[:season], gender_type: options[:gender_type], category_type: options[:category_type]
          )
        elsif season_type.mas_uisp?
          UISPScore.new(
            pool_type: options[:pool_type], event_type: options[:event_type],
            badge: options[:badge],
            season: options[:season], gender_type: options[:gender_type], category_type: options[:category_type]
          )
        else
          raise(ArgumentError, 'New, unsupported or unimplemented SeasonType!')
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity
    end
  end
end
