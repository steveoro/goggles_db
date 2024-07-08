# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = MeetingRelaySwimmer (MRS) model
  #
  #   - version:  7-0.6.21
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

    belongs_to :meeting_relay_result, counter_cache: true
    belongs_to :swimmer
    belongs_to :badge
    belongs_to :stroke_type

    validates_associated :meeting_relay_result
    validates_associated :swimmer
    validates_associated :badge
    validates_associated :stroke_type

    has_many :relay_laps, -> { order('relay_laps.length_in_meters') },
             inverse_of: :meeting_relay_swimmer, dependent: :delete_all

    has_one :season,           through: :meeting_relay_result
    has_one :meeting,          through: :meeting_relay_result
    has_one :meeting_session,  through: :meeting_relay_result
    has_one :meeting_event,    through: :meeting_relay_result
    has_one :meeting_program,  through: :meeting_relay_result
    has_one :event_type,       through: :meeting_relay_result
    has_one :team,             through: :badge
    has_one :gender_type,      through: :swimmer

    default_scope do
      includes(
        :stroke_type, :relay_laps,
        swimmer: [:gender_type],
        badge: [:team],
        meeting_relay_result: %i[meeting meeting_event event_type meeting_program]
      )
    end

    validates :relay_order, presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :reaction_time, presence: true, numericality: true

    # Absolute distance from the start. (Delta length can be computed only when knowing the preceding lap.)
    validates :length_in_meters, presence: { length: { within: 1..5, allow_nil: false } },
                                 numericality: true

    # Absolute timing:
    validates :minutes_from_start,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds_from_start,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths_from_start, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    # Sorting scopes:
    scope :by_order, ->(dir = :asc) { order(relay_order: dir) }

    # Filtering scopes:
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundredths > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundredths: 0) }
    #-- ------------------------------------------------------------------------
    #++

    alias_attribute :parent_result, :meeting_relay_result

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s,
        'swimmer_name' => swimmer.complete_name,
        'swimmer_label' => swimmer.decorate.display_label(locale),
        'team_name' => team.editable_name,
        'team_label' => team.decorate.display_label,
        'event_label' => event_type.label(locale),
        'stroke_code' => stroke_type.code,
        'gender_code' => gender_type.code
      )
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Swimmer
    # associated to this row.
    def swimmer_attributes
      {
        'id' => swimmer.id,
        'short_label' => swimmer.decorate.short_label,
        'complete_name' => swimmer.complete_name,
        'last_name' => swimmer.last_name,
        'first_name' => swimmer.first_name,
        'year_of_birth' => swimmer.year_of_birth,
        'year_guessed' => swimmer.year_guessed,
        'associated_user_label' => swimmer&.associated_user&.decorate&.short_label
      }
    end
  end
end
