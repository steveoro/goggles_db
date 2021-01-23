# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = MeetingEntry model
  #
  #   - version:  7.067
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
        Arel.sql('minutes * 6000 + seconds * 100 + hundreds') => :desc
        # Using an all in one computed column with Arel for ordering is about the same order of speed
        # than using 3 separate as (minutes: :desc, seconds: :desc, hundreds: :desc), but
        # yields slighlty faster results a bit more often. (Tested with benchmarks or real data)
      )
    }
    scope :by_split_gender, lambda {
      includes(:meeting_program)
        .joins(:meeting_program)
        .order(
          'meeting_programs.gender_type_id': :desc, # (Females first)
          no_time: :desc,
          Arel.sql('minutes * 6000 + seconds * 100 + hundreds') => :desc
        )
    }

    # Filtering scopes:
    scope :for_gender_type,   ->(gender_type)   { includes(:meeting_program).joins(:meeting_program).where('meeting_programs.gender_type_id': gender_type.id) }
    scope :for_team,          ->(team)          { includes(:team).joins(:team).where(team_id: team.id) }
    scope :for_category_type, ->(category_type) { includes(:meeting_program).joins(:meeting_program).where('meeting_programs.category_type_id': category_type.id) }
    scope :for_event_type,    ->(event_type)    { includes(:meeting_event).joins(:meeting_event).where('meeting_events.event_type_id': event_type.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the "minimum required" hash of associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => meeting.id,
        'code' => meeting.code,
        'header_year' => meeting.header_year,
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

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      attributes.merge(
        'meeting' => meeting_attributes,
        'meeting_session' => meeting_session_attributes,
        'meeting_program' => meeting_program.minimal_attributes
      ).merge(
        minimal_associations
      ).to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    def minimal_associations
      {
        'team' => team.minimal_attributes,
        'team_affiliation' => team_affiliation.minimal_attributes,
        'swimmer' => swimmer&.minimal_attributes, # (optional)
        'pool_type' => pool_type.lookup_attributes,
        'event_type' => event_type.lookup_attributes,
        'category_type' => category_type.minimal_attributes,
        'gender_type' => gender_type.lookup_attributes
      }
    end
  end
end
