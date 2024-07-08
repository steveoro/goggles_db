# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingEvent model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class MeetingEvent < ApplicationRecord
    self.table_name = 'meeting_events'

    belongs_to :meeting_session
    belongs_to :event_type
    belongs_to :heat_type
    validates_associated :meeting_session
    validates_associated :event_type
    validates_associated :heat_type

    has_one :season,      through: :meeting_session
    has_one :meeting,     through: :meeting_session
    has_one :season_type, through: :meeting_session
    has_one :pool_type,   through: :meeting_session
    has_one :stroke_type, through: :event_type

    has_many :meeting_programs, dependent: :delete_all
    has_many :meeting_individual_results, through: :meeting_programs
    has_many :meeting_relay_results,      through: :meeting_programs
    has_many :meeting_entries,            through: :meeting_programs
    has_many :category_types,             through: :meeting_programs

    has_many :meeting_event_reservations, dependent: :delete_all
    has_many :meeting_relay_reservations, dependent: :delete_all

    default_scope do
      includes(
        :meeting_session, :event_type, :heat_type,
        :season, :meeting, :season_type, :pool_type, :stroke_type
      )
    end

    validates :event_order, presence: { length: { within: 1..3, allow_nil: false } }

    delegate :scheduled_date, to: :meeting_session, prefix: false, allow_nil: false
    delegate :relay?,         to: :event_type, prefix: false, allow_nil: false

    # Sorting scopes:
    scope :by_order, ->(dir = :asc) { order(event_order: dir) }

    # Filtering scopes:
    scope :relays,      -> { joins(:event_type).where('event_types.relay': true) }
    scope :individuals, -> { joins(:event_type).where('event_types.relay': false) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the current event actually takes part in computing the overall ranking
    # for the Meeting.
    #
    # The result is based on the internal stored flag column instead of the possible result obtained
    # by the associated <tt>pool_type.eventable? && stroke_type.eventable?</tt> so that this may act
    # as a possible override for special events.
    def eventable?
      !out_of_race?
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[meeting_session season season_type event_type pool_type stroke_type heat_type]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[meeting_programs]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'display_label' => decorate.display_label(locale),
        'short_label' => decorate.short_label(locale)
      )
    end
  end
end
