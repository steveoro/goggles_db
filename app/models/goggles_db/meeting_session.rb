# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingSession model
  #
  #   - version:  7.034
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
    # has_many :meeting_programs,           through: :meeting_events
    # has_many :meeting_entries,            through: :meeting_events
    # has_many :meeting_individual_results, through: :meeting_programs

    validates :session_order,  presence: { length: { within: 1..2, allow_nil: false } }
    validates :scheduled_date, presence: true
    validates :description,    presence: { length: { maximum: 100, allow_nil: false } }

    alias_attribute :autofilled?, :is_autofilled

    # Sorting scopes:
    scope :by_order,   ->(dir = 'ASC') { order(dir == 'ASC' ? 'session_order ASC' : 'session_order DESC') }
    scope :by_date,    ->(dir = 'ASC') { order(dir == 'ASC' ? 'scheduled_date ASC, session_order ASC' : 'scheduled_date DESC, session_order DESC') }

    def self.by_meeting(dir = 'ASC')
      sorting_order = if dir == 'ASC'
                        'meetings.description ASC, session_order ASC'
                      else
                        'meetings.description DESC, session_order DESC'
                      end
      includes(:pool_type).joins(:meeting).order(sorting_order)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes the 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'meeting' => meeting.attributes,
        'season' => season.attributes,
        'season_type' => season_type.attributes,
        # Optional:
        'swimming_pool' => swimming_pool&.attributes,
        'pool_type' => pool_type&.attributes,
        'day_part_type' => day_part_type&.attributes
      ).to_json(options)
    end
  end
end
