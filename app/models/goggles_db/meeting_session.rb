# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingSession model
  #
  #   - version:  7-0.6.30
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
    has_many :event_types,       through: :meeting_events
    has_many :meeting_programs,  through: :meeting_events
    has_many :meeting_entries,   through: :meeting_events
    # has_many :meeting_individual_results, through: :meeting_programs

    default_scope do
      includes(
        :meeting, :swimming_pool, :day_part_type,
        :season, :season_type, :pool_type
      )
    end

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
      includes(:meeting, :pool_type)
        .joins(:meeting)
        .order('meetings.description': dir, session_order: dir)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[meeting_events]
    end

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
  end
end
