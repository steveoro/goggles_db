# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = MeetingEntry model
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  # This model should be used for *individual* startlist entries only,
  # even though the structure could be used for relays as well.
  #
  # (It even has the #relay? helper to discriminate any relay entries
  # from the rest, but this should never be used from this version onward.)
  #
  # Relay results are able to store entry data directly inside MRR rows.
  # Frequently the MRR itself is used to setup or optimize the relay entry
  # up until the last second before the relay registration term (which may fall after
  # the actual start of the Meeting itself).
  #
  class MeetingEntry < ApplicationRecord
    self.table_name = 'meeting_entries'
    include TimingManageable

    belongs_to :meeting_program
    belongs_to :team
    belongs_to :team_affiliation
    validates_associated :meeting_program
    validates_associated :team
    validates_associated :team_affiliation

    default_scope { left_outer_joins(:swimmer) }

    has_one :meeting,         through: :meeting_program
    has_one :meeting_session, through: :meeting_program
    has_one :meeting_event,   through: :meeting_program
    has_one :pool_type,       through: :meeting_program
    has_one :event_type,      through: :meeting_program
    has_one :category_type,   through: :meeting_program
    has_one :gender_type,     through: :meeting_program

    # These reference fields may be filled-in later (thus not validated upon creation):
    belongs_to :swimmer, optional: true
    belongs_to :badge, optional: true
    belongs_to :entry_time_type, optional: true

    delegate :relay?,      to: :event_type, prefix: false, allow_nil: false
    delegate :intermixed?, to: :gender_type, prefix: false, allow_nil: false
    delegate :male?,       to: :gender_type, prefix: false, allow_nil: false
    delegate :female?,     to: :gender_type, prefix: false, allow_nil: false

    # Sorting scopes:
    scope :by_swimmer, -> { includes(:swimmer).joins(:swimmer).order('swimmers.complete_name') }
    scope :by_number, lambda {
      order(
        start_list_number: :asc,
        no_time: :desc,
        Arel.sql('minutes * 6000 + seconds * 100 + hundredths') => :desc
        # Using an all in one computed column with Arel for ordering is about the same order of speed
        # than using 3 separate as (minutes: :desc, seconds: :desc, hundredths: :desc), but
        # yields slighlty faster results a bit more often. (Tested with benchmarks or real data)
      )
    }
    scope :by_split_gender, lambda {
      includes(:meeting_program)
        .joins(:meeting_program)
        .order(
          'meeting_programs.gender_type_id': :desc, # (Females first)
          no_time: :desc,
          Arel.sql('minutes * 6000 + seconds * 100 + hundredths') => :desc
        )
    }

    # Filtering scopes:
    scope :for_gender_type,   ->(gender_type)   { includes(:meeting_program).joins(:meeting_program).where('meeting_programs.gender_type_id': gender_type.id) }
    scope :for_team,          ->(team)          { includes(:team).joins(:team).where(team_id: team.id) }
    scope :for_category_type, ->(category_type) { includes(:meeting_program).joins(:meeting_program).where('meeting_programs.category_type_id': category_type.id) }
    scope :for_event_type,    ->(event_type)    { includes(:meeting_event).joins(:meeting_event).where('meeting_events.event_type_id': event_type.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[meeting meeting_session meeting_program team_affiliation team swimmer
         pool_type event_type category_type gender_type]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'timing' => to_timing.to_s,
        'swimmer_name' => swimmer&.complete_name,
        'swimmer_label' => swimmer&.decorate&.display_label(locale),
        'team_name' => team.editable_name,
        'team_label' => team.decorate.display_label
      )
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

    # Similarly to <tt>#meeting_attributes</tt>, this returns a commodity Hash
    # summarizing the MeetingSession associated to this row.
    def meeting_session_attributes
      {
        'id' => meeting_session.id,
        'session_order' => meeting_session.session_order,
        'scheduled_date' => meeting_session.scheduled_date
      }
    end
  end
end
