# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = MeetingRelaySwimmer (MRS) model
  #
  #   - version:  7.02.09
  #   - author:   Steve A.
  #
  # == Note:
  # MRS includes lap info & direct stroke_type reference as 1st-level
  # association because it's the "lap entity"-version dedicated to relays (MRRs),
  # whereas Lap is currently for MIRs only.
  #
  class MeetingRelaySwimmer < ApplicationRecord
    self.table_name = 'meeting_relay_swimmers'
    include TimingManageable

    belongs_to :meeting_relay_result
    belongs_to :swimmer
    belongs_to :badge
    belongs_to :stroke_type

    validates_associated :meeting_relay_result
    validates_associated :swimmer
    validates_associated :badge
    validates_associated :stroke_type

    has_one  :meeting,          through: :meeting_relay_result
    has_one  :meeting_session,  through: :meeting_relay_result
    has_one  :meeting_event,    through: :meeting_relay_result
    has_one  :meeting_program,  through: :meeting_relay_result
    has_one  :event_type,       through: :meeting_relay_result
    has_one  :team,             through: :badge

    validates :relay_order, presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :reaction_time, presence: true, numericality: true

    # Sorting scopes:
    scope :by_order, ->(dir = :asc) { order(relay_order: dir) }
    # TODO: CLEAR UNUSED
    # scope :by_swimmer, ->(dir = :asc) { joins(:swimmer).order('swimmers.last_name': dir, 'swimmers.first_name': dir) }
    # scope :by_badge,   ->(dir = :asc) { joins(:badge).order('badges.number': dir) }
    # scope :by_stroke_type, ->(dir = :asc) { joins(:stroke_type).order('stroke_types.code': dir) }

    # Filtering scopes:
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundredths > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundredths: 0) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the minimum required 1st-level attributes & associations.
    #
    def minimal_attributes
      super.merge(
        'timing' => to_timing.to_s
      ).merge(minimal_associations)
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Swimmer
    # associated to this row.
    def swimmer_attributes
      {
        'id' => swimmer.id,
        'display_label' => swimmer.decorate.display_label,
        'short_label' => swimmer.decorate.short_label,
        'complete_name' => swimmer.complete_name,
        'last_name' => swimmer.last_name,
        'first_name' => swimmer.first_name,
        'year_of_birth' => swimmer.year_of_birth,
        'year_guessed' => swimmer.year_guessed
      }
    end

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      attributes.merge(
        'timing' => to_timing.to_s,
        'meeting_relay_result' => meeting_relay_result.minimal_attributes,
        'team' => team.minimal_attributes,
        # (Badge already includes swimmer_attributes)
        'badge' => badge.minimal_attributes,
        'event_type' => event_type.lookup_attributes,
        'stroke_type' => stroke_type.lookup_attributes
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
        'gender_type' => swimmer.gender_type.lookup_attributes,
        'stroke_type' => stroke_type.lookup_attributes
      }
    end
  end
end
