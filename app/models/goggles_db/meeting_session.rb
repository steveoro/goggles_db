# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingSession model
  #
  #   - version:  7-0.3.33
  #   - author:   Steve A.
  #
  class MeetingSession < ApplicationRecord
    self.table_name = 'meeting_sessions'

    belongs_to :meeting
    belongs_to :swimming_pool, optional: true # (can be set later on)
    belongs_to :day_part_type, optional: true # (can be set later on)

    validates_associated :meeting

    has_one  :season,      through: :meeting
    has_one  :season_type, through: :meeting
    has_one  :pool_type,   through: :swimming_pool

    has_many :meeting_events, -> { order(:event_order) }, dependent: :delete_all
    has_many :event_types,    through: :meeting_events
    has_many :meeting_programs,           through: :meeting_events
    has_many :meeting_entries,            through: :meeting_events
    # has_many :meeting_individual_results, through: :meeting_programs

    validates :session_order,  presence: { length: { within: 1..2, allow_nil: false } }
    validates :scheduled_date, presence: true
    validates :description,    presence: { length: { maximum: 100, allow_nil: false } }

    # Sorting scopes:
    scope :by_order, ->(dir = :asc) { order(session_order: dir) }
    scope :by_date,  ->(dir = :asc) { order(scheduled_date: dir, session_order: dir) }

    # Sort by Meeting(description)
    # == Params
    # - dir: :asc|:desc
    def self.by_meeting(dir = :asc)
      includes(:pool_type).joins(:meeting).order('meetings.description': dir, session_order: dir)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => meeting.id,
        'code' => meeting.code,
        'header_year' => meeting.header_year,
        'display_label' => meeting.decorate.display_label,
        'short_label' => meeting.decorate.short_label,
        'edition_label' => meeting.edition_label
      }
    end

    # Override: includes the 1st-level associations into the typical to_json output.
    # == Params
    # - options: can be any option hash accepted by JSON#generate
    def to_json(options = nil)
      attributes.merge(
        'meeting' => meeting_attributes,
        'season' => season.minimal_attributes,
        'season_type' => season_type.minimal_attributes,
        # Optional:
        'swimming_pool' => swimming_pool&.minimal_attributes,
        'pool_type' => pool_type&.lookup_attributes,
        'day_part_type' => day_part_type&.lookup_attributes
      ).to_json(options)
    end
  end
end
