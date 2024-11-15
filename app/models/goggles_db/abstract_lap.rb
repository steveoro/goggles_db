# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Lap model
  #
  # Encapsulates common behavior for Laps & User Laps.
  #
  #   - version:  7-0.7.24
  #   - author:   Steve A.
  #
  class AbstractLap < ApplicationRecord
    self.abstract_class = true

    include TimingManageable

    # Absolute distance from the start. (Delta length can be computed only when knowing the preceding lap.)
    validates :length_in_meters, presence: { length: { within: 1..5, allow_nil: false } },
                                 numericality: true

    # Delta timing:
    validates :minutes,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    # Absolute timing:
    validates :minutes_from_start,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds_from_start,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths_from_start, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    # Sorting scopes:
    scope :by_distance, -> { order(:length_in_meters) }

    # Filtering scopes:
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundredths > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundredths: 0) }

    # All siblings laps:
    scope :related_laps, lambda { |lap|
      includes(parent_association_sym, :swimmer, :gender_type, :event_type)
        .where(lap.parent_result_where_condition)
        .by_distance
    }
    # All preceding laps, including the current one:
    scope :summing_laps, ->(lap) { related_laps(lap).where("#{lap.class.table_name}.length_in_meters <= ?", lap.length_in_meters) }
    # Just the laps following the specified one:
    scope :following_laps, ->(lap) { related_laps(lap).where("#{lap.class.table_name}.length_in_meters > ?", lap.length_in_meters) }
    #-- -----------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[swimmer gender_type]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s, # (delta timing)
        'timing_from_start' => timing_from_start.to_s # (actual lap timing)
      )
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def meeting_attributes
      {
        'id' => parent_meeting&.id,
        'code' => parent_meeting&.code,
        'header_year' => parent_meeting&.header_year,
        'display_label' => parent_meeting&.decorate&.display_label,
        'short_label' => parent_meeting&.decorate&.short_label,
        'edition_label' => parent_meeting&.edition_label
      }
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    alias user_workshop_attributes meeting_attributes # (new, old)
    # (Needed by app/models/goggles_db/application_record.rb:122)

    # Returns a commodity Hash wrapping the essential data that summarizes the Swimmer
    # associated to this row.
    def swimmer_attributes
      {
        'id' => swimmer_id,
        'complete_name' => swimmer.complete_name,
        'last_name' => swimmer.last_name,
        'first_name' => swimmer.first_name,
        'year_of_birth' => swimmer.year_of_birth,
        'year_guessed' => swimmer.year_guessed
      }
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns the single lap row preceding this one by distance, if any; +nil+ otherwise.
    def previous_lap
      self.class.related_laps(self).where("#{self.class.table_name}.length_in_meters < ?", length_in_meters).last
    end

    # ADD recompute_delta method using same strategy as in main

    # Returns the Timing instance storing the lap timing from the start of the race.
    #
    # If the "_from_start" fields have not been filled in, this will try to recompute the
    # absolute timing using all deltas
    #
    # (Note that this will imply 3 summing queries and it may fail to yield correct values
    #  if the preceding deltas are not set.)
    def timing_from_start
      # Quick way to detect if the timing from start is already set:
      lap_present = minutes_from_start.positive? || seconds_from_start.positive? || hundredths_from_start.positive?
      if lap_present
        Timing.new(
          hundredths: hundredths_from_start,
          seconds: seconds_from_start,
          minutes: minutes_from_start
        )
      else
        laps = self.class.summing_laps(self)
        Timing.new(
          hundredths: laps.sum(:hundredths),
          seconds: laps.sum(:seconds),
          minutes: laps.sum(:minutes)
        )
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    protected

    class << self
      # Returns the parent association symbol.
      # (either MIR or UserResult, depending on the sibling class)
      #
      # ==> OVERRIDE IN SIBLINGS <==
      def parent_association_sym; end
    end

    class << self
      # Returns the column symbol used for the parent association with a result row.
      # (either MIR or UserResult, depending on the sibling class)
      #
      # ==> OVERRIDE IN SIBLINGS <==
      def parent_result_column_sym; end
    end

    # Generalization for the parent association with a Meeting or a UserWorkshop entity.
    # Returns either one or the other, depending on what the sibling responds to.
    #
    # ==> OVERRIDE IN SIBLINGS <==
    def parent_meeting; end

    # Returns the actual parent association with a result row
    # (either MIR or UserResult, depending on the sibling class)
    #
    # ==> OVERRIDE IN SIBLINGS <==
    def parent_result; end

    # Returns the column value used for the parent association with a result row
    # (either MIR or UserResult, depending on the sibling class)
    #
    # ==> OVERRIDE IN SIBLINGS <==
    def parent_result_id; end

    # Generalization for parent association binding with MIR or UserResult.
    # Returns the association "where" condition, based on the ID value of either the MIR or the UserResult,
    # depending on what the sibling responds to.
    #
    # ==> OVERRIDE IN SIBLINGS <==
    def parent_result_where_condition; end
  end
end
