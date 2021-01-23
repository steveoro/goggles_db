# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = Lap model
  #
  #   - version:  7.068
  #   - author:   Steve A.
  #
  # == Note:
  # Lap is currently dedicated to MIRs *only*: use MeetingRelaySwimmer (MRS)
  # to store lap data for MRRs.
  #
  class Lap < ApplicationRecord
    self.table_name = 'laps'
    include TimingManageable

    # [Steve A.] These 3 are actually optional but always "filled by hand":
    belongs_to :meeting_program
    belongs_to :swimmer
    belongs_to :team
    validates_associated :meeting_program
    validates_associated :swimmer
    validates_associated :team

    belongs_to :meeting_individual_result, optional: true
    belongs_to :meeting_entry_id, optional: true

    has_one :meeting,    through: :meeting_program
    has_one :event_type, through: :meeting_program
    has_one :pool_type,  through: :meeting_program

    # belongs_to :meeting_entry
    # has_one :badge,           through: :meeting_entry

    validates :length_in_meters, presence: { length: { within: 1..5, allow_nil: false } },
                                 numericality: true

    validates :minutes,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundreds, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    validates :stroke_cycles, length: { within: 1..3 }, allow_nil: true
    validates :breath_cycles, length: { within: 1..3 }, allow_nil: true
    validates :position,      length: { within: 1..4 }, allow_nil: true

    validates :underwater_kicks,    length: { within: 1..3 }, allow_nil: true
    validates :underwater_seconds,  length: { within: 1..2 }, allow_nil: true
    validates :underwater_hundreds, length: { within: 1..2 }, allow_nil: true

    # Sorting scopes:
    scope :by_distance, -> { order(:length_in_meters) }

    # Filtering scopes:
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundreds > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundreds: 0) }

    # TODO: CLEAR UNUSED
    # scope :for_event_type, ->(event_type) { joins(:event_type).where('event_types.id': event_type.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the minimum required 1st-level associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Swimmer
    # associated to this row.
    def swimmer_attributes
      {
        'id' => swimmer.id,
        'complete_name' => swimmer.complete_name,
        'last_name' => swimmer.last_name,
        'first_name' => swimmer.first_name,
        'year_of_birth' => swimmer.year_of_birth,
        'year_guessed' => swimmer.year_guessed
      }
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => meeting&.id,
        'code' => meeting&.code,
        'header_year' => meeting&.header_year,
        'edition_label' => meeting&.edition_label
      }
    end

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      # [Steve A.] Using the safe-access operator because here there's no actual foreign key enforcement on associations:
      attributes.merge(
        'meeting_program' => meeting_program&.minimal_attributes,
        'swimmer' => swimmer_attributes,
        'team' => team&.minimal_attributes,
        'meeting' => meeting_attributes,
        'meeting_individual_result' => meeting_individual_result&.minimal_attributes,
        'event_type' => event_type&.lookup_attributes,
        'pool_type' => pool_type&.lookup_attributes
      ).to_json(options)
    end

    private

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
