# frozen_string_literal: true

require 'fuzzystringmatch'

module GogglesDb
  #
  # = DbFinders module
  #
  # Wraps all finder strategies that can be plugged into CmdFindEntryTime by the
  # dedicated factory.
  #
  # The factory will choose & build which strategy has to be used by the command object
  # depending on the specified EntryTimeType.
  #
  module DbFinders
    #
    # = BaseStrategy parent object
    #   - version:  7-0.5.01
    #   - author:   Steve A.
    #   - build:    20230323
    #
    # Encapsulates the base interface for its siblings.
    #
    class BaseStrategy
      attr_reader :matches

      # Any text distance >= DEFAULT_MATCH_BIAS will be considered viable as a match
      # (unless this default value is ovverriden in the constructor of the sibling class).
      DEFAULT_MATCH_BIAS = 0.89 unless defined?(DEFAULT_MATCH_BIAS)
      #-- -----------------------------------------------------------------------
      #++

      # Creates a new base strategy instance.
      #
      # The base strategy works by searching on a specific model domain using the search terms
      # and using any search scope (typically a custom scope on the model).
      #
      # Then, each row on this scoped domain is given a match score using a fuzzy-string matching
      # algorithm: if the score passes the bias, the row is kept, otherwise it's discarded from
      # the results.
      #
      # == Notes on the matching strategies:
      # - equal matches will be assigned a perfect score;
      # - sub-strings matching the search term, if discarded by the fuzzy-logic will be reinstated
      #   with a minimum bias score (this helps getting results even by typing a few keystrokes for the search)
      #
      # == Options:
      # - <tt>:model_klass</tt>: *required* target model class for the search
      #
      # - <tt>search_terms</tt>: a *required* +Hash+ of search terms having the
      #   form: <tt>{ column_name1 => "target value", ... }</tt>, with the column names as symbols;
      #
      #   Add a <tt>toggle_debug: true</tt> element in <tt>search_terms</tt> to enable
      #   the verbose search output on the console (default: false); this will be removed from
      #   the search terms.
      #
      #   === NOTE:
      #   The first column name specified in the search terms is the one assumed to be the main target
      #   of the search and will also be:
      #   - the main and only parameter for the search method that will in turn build up the domain;
      #   - the main column used for debug output.
      #   The remaining other search fields will be used to further filter down the initial base domain.
      #
      #   === Example:
      #   - model_klass: Team, search_terms: { editable_name: "<whatever>", city_id: 39 }
      #     => will filter the base domain returned by the for_name() scope with only the rows matching the city_id
      #
      # - <tt>:search_method</tt>: search method called on the model class to
      #   build up the base domain (default: <tt>:for_name</tt> scope, which usually is a FULL-TEXT search).
      #
      # - <tt>:bias</tt>: override for the <tt>DEFAULT_MATCH_BIAS</tt> used to decide
      #   if a resulting weight is a match (">=").
      #
      def initialize(model_klass, search_terms = {}, search_method = :for_name, bias = DEFAULT_MATCH_BIAS) # rubocop:disable Metrics/CyclomaticComplexity
        @toggle_debug = search_terms[:toggle_debug] || false
        search_terms.reject! { |key, _v| key == :toggle_debug }
        raise(ArgumentError, 'No search term specified') if search_terms.blank? || !search_terms.is_a?(Hash)
        raise(ArgumentError, 'No model class specified') if model_klass.blank?
        # (NOTE: blank search values shall be handled later on by prepare_values())
        raise(ArgumentError, 'Blank target column (key) name specified') if search_terms.keys.first.blank?

        @model_klass = model_klass
        @target_key, @target_value = search_terms.first
        @filtering_terms = search_terms.reject { |key, _v| key == @target_key }
        @search_method = search_method
        @bias = bias
        @candidate_struct = Struct.new(:candidate, :weight)
        @matches = []
      end

      # Returns a stripped-down, pure ASCII 7-bit version of the specified value. Handles possible nil values.
      # In its base implementation just removes foreign accented letters and downcases the result string.
      # == Params
      # - +value+: the string value to be "normalized".
      def normalize_value(value)
        value.to_s.tr('à', 'a').gsub('[èé]', 'e').tr('ì', 'i')
             .tr('ò', 'o').tr('ù', 'u').tr('ç', 'c')
             .downcase
      end
      #-- ---------------------------------------------------------------------
      #++

      # Fills the </tt>matches</tt> array by additionally filtering the base domain
      # retrieved using a MATCH query, then loops on all the filtered results
      # computing the distance weight and adding them to the result array if the
      # computed weight reaches at least the match </tt>bias</tt>.
      #
      # Updates directly the internal </tt>matches</tt> list with the matching candidates
      # in found order (call </tt>#sort_matches</tt> afterwards to sort the array using weights).
      #
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def scan_for_matches
        domain = @model_klass.send(@search_method, @target_value)
        if @toggle_debug.present?
          Rails.logger.debug { "DbFinders::BaseStrategy(#{@model_klass})" }
          Rails.logger.debug { "- tot. domain rows: #{domain.count}" }
        end

        domain.each do |candidate_row|
          Rails.logger.debug { "=> '#{candidate_row.send(@target_key)}'" } if @toggle_debug.present?
          # Precedence to the exact matches - move fwd if there are obvious differences
          # in filter mismatches:
          next if @filtering_terms.any? { |key, value| candidate_row.send(key) != value }

          Rails.logger.debug '   next passed' if @toggle_debug.present?

          # Check a perfect match without computing the score:
          if candidate_row.send(@target_key) == @target_value
            @matches << @candidate_struct.new(candidate_row, 1.0)
            Rails.logger.debug '   perfect match found' if @toggle_debug.present?
            break
          end

          weight = compute_best_weight(candidate_row)
          Rails.logger.debug { "   result weight = #{weight} (vs. >= #{@bias})" } if @toggle_debug.present?
          # Store candidate if it seems to be a match but also if it's a substring (possibly returned by LIKEs):
          # (this allows returning results even when the search contains just a few typed chars)
          if weight >= @bias
            @matches << @candidate_struct.new(candidate_row, weight)
          elsif candidate_row.send(@target_key).to_s.include?(@target_value.to_s)
            # Give substrings a "political" weight equal to the bias, because the metric score possibly will be very low:
            @matches << @candidate_struct.new(candidate_row, @bias)
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Sorts the internal </tt>matches</tt> array according to the computed Jaro-Winkler
      # text metric distance.
      def sort_matches
        return if @matches.empty?

        # Sort in descending order:
        @matches.sort! { |a, b| b.weight <=> a.weight }
        return if @toggle_debug.blank?

        # Output verbose debugging output:
        Rails.logger.debug { "\r\n\r\n[#{@target_value}]" }
        @matches.each_with_index do |obj, index|
          Rails.logger.debug "#{index}. #{obj.candidate.send(@target_key)} (#{obj.weight})"
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      private

      # Internal instance of the metric used to compute text distance
      METRIC = FuzzyStringMatch::JaroWinkler.create(:native)

      # Returns the target search value, the current match candidate and its corresponding
      # normalized value all "namespaced" using the relevant filtering terms, so that the string metric
      # can evaluate all fields at once.
      #
      # == Params
      # - <tt>candidate_row</tt>: the current candidate row for the search match
      #
      # == Returns
      # An array having as items:
      # - <tt>searched_value</tt>, target of the search
      # - <tt>current_value</tt>, current element
      # - <tt>normalized_target</tt>, "normalized"  version of the search value
      # - <tt>normalized_value</tt>, "normalized" current element
      # The filtering fields are used as most significant (discriminating) parts in the namespace
      # respecting found order.
      #
      def prepare_values(candidate_row)
        target_namespace = @filtering_terms.values.join('/')
        curr_namespace = @filtering_terms.map { |key, _value| candidate_row.send(key) }
        [
          "#{target_namespace}/#{@target_value.to_s.downcase}",
          "#{curr_namespace}/#{candidate_row.send(@target_key).downcase}",
          "#{target_namespace}/#{normalize_value(@target_value)}",
          "#{curr_namespace}/#{normalize_value(candidate_row.send(@target_key))}"
        ]
      end

      # Returns the computed weight between the <tt>searched_value</tt> and:
      #
      # 1. the <tt>:current_value</tt>, if it's a suitable match;
      # 2. the <tt>:normalized_value</tt> otherwise.
      #
      # The normalized version of the value assumes that the candidate search value may
      # include accented letters or foreign alphabets in it.
      #
      # == Params:
      # - <tt>:candidate_row</tt>: the current candidate row for the match
      #
      def compute_best_weight(candidate_row)
        # Prepare a namespaced-like version of the comparison values, "namespacing"-them
        # with all other filtering key-fields:
        searched_value, current_value, normalized_target, normalized_value = prepare_values(candidate_row)

        # Check the distance between the searched name the current candidate name:
        weight = METRIC.getDistance(current_value, searched_value)
        return weight if weight >= @bias
        return 0.0 if normalized_value.blank?

        # No match yet? Check also the normalized versions:
        METRIC.getDistance(normalized_value, normalized_target)
      end
    end
  end
end
