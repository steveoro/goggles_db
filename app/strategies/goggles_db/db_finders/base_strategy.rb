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
      # (unless this default value is overridden in the constructor of the sibling class).
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
      # == Additional options:
      # - <tt>:score_columns</tt>: an optional list of *additional* column names (symbols) that will
      #   also be scored against the target value, taking the *maximum* resulting weight among all of
      #   them and the main target column. This allows a candidate to be considered a strong match
      #   when any of its alternative name columns (e.g. <tt>editable_name</tt>, <tt>name_variations</tt>)
      #   matches the search value, even when the main column (e.g. <tt>name</tt>) differs.
      #   (Default: empty => only the target column is scored, preserving the original behavior.)
      #
      # - <tt>:multi_value_columns</tt>: an optional list of column names (symbols) whose stored value
      #   may contain *multiple* alternative values separated by a comma (<tt>,</tt>) or a semicolon
      #   (<tt>;</tt>). Each token is stripped and scored individually, keeping the best weight.
      #   (Default: empty.)
      #
      # Both lists are declared by the sibling strategy and are *never* treated as exact-match filters
      # (they are removed from the filtering terms even if specified among the search terms).
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(model_klass, search_terms = {}, search_method = :for_name, bias = DEFAULT_MATCH_BIAS,
                     score_columns = [], multi_value_columns = [])
        @toggle_debug = search_terms[:toggle_debug] || false
        search_terms.reject! { |key, _v| key == :toggle_debug }
        raise(ArgumentError, 'No search term specified') if search_terms.blank? || !search_terms.is_a?(Hash)
        raise(ArgumentError, 'No model class specified') if model_klass.blank?
        # (NOTE: blank search values shall be handled later on by prepare_values())
        raise(ArgumentError, 'Blank target column (key) name specified') if search_terms.keys.first.blank?

        @model_klass = model_klass
        @target_key, @target_value = search_terms.first
        @score_columns = ([@target_key] + Array(score_columns)).uniq
        @multi_value_columns = Array(multi_value_columns).to_set
        # Alias name-columns used for scoring must never act as exact-match filters:
        @filtering_terms = search_terms.except(*@score_columns)
        @search_method = search_method
        @bias = bias
        @candidate_struct = Struct.new(:candidate, :weight)
        @matches = []
      end
      # rubocop:enable Metrics/ParameterLists

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
      # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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

          # Check a perfect match (on any scored column) without computing the score:
          if perfect_match?(candidate_row)
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
          elsif substring_match?(candidate_row)
            # Give substrings a "political" weight equal to the bias, because the metric score possibly will be very low:
            @matches << @candidate_struct.new(candidate_row, @bias)
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

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

      # Internal instance of the metric used to compute text distance
      METRIC = FuzzyStringMatch::JaroWinkler.create(:native)

      private

      # Expands a candidate column value into the list of non-blank comparison strings.
      # Multi-value columns (declared via <tt>multi_value_columns</tt>) are split on a comma
      # (<tt>,</tt>) or a semicolon (<tt>;</tt>) and each token is stripped; all other columns
      # yield a single stripped value.
      #
      # == Params:
      # - <tt>column</tt>: the column name (symbol)
      # - <tt>value</tt>: the raw stored value for that column
      #
      def expand_column_values(column, value)
        return [] if value.blank?

        if @multi_value_columns.include?(column)
          value.to_s.split(/[,;]/).map(&:strip).compact_blank
        else
          [value.to_s.strip]
        end
      end

      # Returns +true+ if any scored column of the candidate row holds a value that equals
      # (case-insensitively) the search target value.
      def perfect_match?(candidate_row)
        @score_columns.any? do |column|
          expand_column_values(column, candidate_row.send(column)).any? do |raw_value|
            raw_value.casecmp?(@target_value.to_s.strip)
          end
        end
      end

      # Returns +true+ if any scored column of the candidate row holds a value that includes
      # the search target value as a substring (used to reinstate LIKE-only matches).
      def substring_match?(candidate_row)
        @score_columns.any? do |column|
          expand_column_values(column, candidate_row.send(column)).any? do |raw_value|
            raw_value.include?(@target_value.to_s)
          end
        end
      end

      # Returns the best (maximum) Jaro-Winkler weight between the search target value and all
      # the scored columns of the candidate row (<tt>@score_columns</tt>), expanding multi-value
      # columns into individual tokens.
      #
      # Each comparison is "namespaced" with the remaining filtering key-fields so that the string
      # metric can evaluate all relevant fields at once. Both the raw (downcased) and the
      # "normalized" versions of each value are scored; the normalized version assumes the candidate
      # search value may include accented letters or foreign alphabets.
      #
      # == Params:
      # - <tt>:candidate_row</tt>: the current candidate row for the match
      #
      def compute_best_weight(candidate_row)
        target_namespace = @filtering_terms.values.join('/')
        curr_namespace = @filtering_terms.map { |key, _value| candidate_row.send(key) }
        searched_value = "#{target_namespace}/#{@target_value.to_s.downcase}"
        normalized_target = "#{target_namespace}/#{normalize_value(@target_value)}"
        best = 0.0

        @score_columns.each do |column|
          expand_column_values(column, candidate_row.send(column)).each do |raw_value|
            current_value = "#{curr_namespace}/#{raw_value.downcase}"
            weight = METRIC.getDistance(current_value, searched_value)
            best = weight if weight > best

            # Also score the "normalized" version (accented/foreign alphabets handling):
            normalized_value = "#{curr_namespace}/#{normalize_value(raw_value)}"
            nweight = METRIC.getDistance(normalized_value, normalized_target)
            best = nweight if nweight > best
          end
        end

        best
      end
    end
  end
end
