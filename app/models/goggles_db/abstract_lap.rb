# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Lap model
  #
  # Encapsulates common behavior for Laps & User Laps.
  #
  #   - version:  7.02.18
  #   - author:   Steve A.
  #
  class AbstractLap < ApplicationRecord
    self.abstract_class = true

    include TimingManageable

    validates :length_in_meters, presence: { length: { within: 1..5, allow_nil: false } },
                                 numericality: true

    validates :minutes,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    # Sorting scopes:
    scope :by_distance, -> { order(:length_in_meters) }

    # Filtering scopes:
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundredths > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundredths: 0) }

    # All siblings laps:
    scope :related_laps, ->(lap) { by_distance.where(lap.parent_result_where_condition) }
    # All preceding laps, including the current one:
    scope :summing_laps, ->(lap) { related_laps(lap).where('length_in_meters <= ?', lap.length_in_meters) }
    #-- -----------------------------------------------------------------------
    #++

    # Returns the Timing instance storing the lap timing from the start of the race.
    # If the "_from_start" fields have not been filled with data, the Timing value
    # will be computed.
    def timing_from_start
      if seconds_from_start.to_i.positive?
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

    # Override: include the minimum required 1st-level associations.
    #
    def minimal_attributes
      super.merge(
        'timing' => to_timing.to_s,
        'timing_from_start' => timing_from_start.to_s
      ).merge(minimal_associations)
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => parent_meeting&.id,
        'code' => parent_meeting&.code,
        'header_year' => parent_meeting&.header_year,
        'edition_label' => parent_meeting&.edition_label
      }
    end

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

    protected

    class << self
      # Returns the column symbol used for the parent association with a result row
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

    # Returns the "minimum required" hash of associations.
    #
    # === Note:
    # Typically these should be a subset of the (full) associations enlisted
    # inside #to_json.
    # The rationale here is to select just the bare amount of "leaf entities"
    # in the hierachy tree so that these won't be included more than once in
    # any #minimal_attributes output invoked from a higher level or parent entity.
    #
    # Example:
    # #to_json or #attributes of team_affilition.badges vs single badge output.
    def minimal_associations
      {
        'swimmer' => swimmer_attributes,
        'gender_type' => swimmer.gender_type.lookup_attributes
      }
    end
  end
end