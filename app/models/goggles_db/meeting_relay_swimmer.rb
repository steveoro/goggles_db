# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingRelaySwimmer model
  #
  #   - version:  7.035
  #   - author:   Steve A.
  #
  class MeetingRelaySwimmer < ApplicationRecord
    self.table_name = 'meeting_relay_swimmers'

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
    #-- ------------------------------------------------------------------------
    #++

    # Returns a new Timing instance initialized with the timing data from this row
    # (@see lib/wrappers/timing.rb)
    #
    def to_timing
      # MIR doesn't hold an "hour" column due to the typical short time span of the competition:
      Timing.new(hundreds, seconds, minutes % 60, 60 * (minutes / 60))
    end

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      attributes.merge(
        'meeting_relay_result' => meeting_relay_result.attributes,
        'team' => team.attributes,
        'swimmer' => swimmer.attributes,
        'badge' => badge.attributes,
        'event_type' => event_type.attributes,
        'stroke_type' => stroke_type.attributes
      ).to_json(options)
    end
  end
end
