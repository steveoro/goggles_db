# frozen_string_literal: true

require 'singleton'

module GogglesDb
  module DbFinders
    #
    # = DbFinders singleton factory
    #
    #   - version:  7-0.4.01
    #   - author:   Steve A.
    #   - build:    20220804
    #
    # Allows to create a plug-in strategy object for finding a specific entity given the search
    # parameters.
    #
    class Factory
      include Singleton

      # Returns a dedicated finder strategy instance depending on the specified model class.
      #
      # == Params
      # - <tt>model_klass</tt>: the target AR model.
      #
      # - <tt>search_terms</tt>: a *required* +Hash+ of search terms having the
      #   form: <tt>{ column_name1 => "target value", ... }</tt>, with the column names as symbols;
      #
      #   === Notes:
      #   Be aware that only certain column symbols will be allowed as search terms, depending
      #   on the target <tt>model_klass</tt> (see implementation for further details; this depends
      #   also on the used search scope, which is typically :for_name and has a single parameter).
      #
      #   Add a <tt>toggle_debug: true</tt> element in <tt>search_terms</tt> to enable
      #   the verbose search output on the console (default: false); this will be removed from
      #   the search terms (as all other column names non valid as search terms).
      #
      # == Returns
      # A <tt>DbFinders::BaseStrategy</tt> sibling
      #
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.for(model_klass, search_terms = {})
        raise(ArgumentError, 'No search term specified') if search_terms.blank? ||
                                                            search_terms.reject { |k, _v| k == :toggle_debug }.blank?

        if model_klass == GogglesDb::Swimmer
          # Add also strict parameter checking for the search terms in all models, like this:
          search_terms.keep_if { |key, _v| %i[complete_name year_of_birth gender_type_id toggle_debug].include?(key) }
          FuzzySwimmer.new(search_terms)

        elsif model_klass == GogglesDb::Team
          search_terms.keep_if { |key, _v| %i[name editable_name name_variations city_id toggle_debug].include?(key) }
          FuzzyTeam.new(search_terms)

        elsif model_klass == GogglesDb::SwimmingPool
          search_terms.keep_if { |key, _v| %i[name nick_name pool_type_id city_id toggle_debug].include?(key) }
          FuzzyPool.new(search_terms)

        elsif model_klass == GogglesDb::Meeting
          search_terms.keep_if { |key, _v| %i[description code header_year season_id toggle_debug].include?(key) }
          FuzzyMeeting.new(search_terms)

        elsif model_klass == GogglesDb::City
          search_terms.keep_if { |key, _v| %i[name area country country_code toggle_debug].include?(key) }
          FuzzyCity.new(search_terms)

        else
          raise(ArgumentError, 'New, unsupported or unimplemented model class!')
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
