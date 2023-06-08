# frozen_string_literal: true

module GogglesDb
  #
  # = Meeting model
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  class Meeting < AbstractMeeting
    self.table_name = 'meetings'

    belongs_to :home_team, optional: true, class_name: 'Team' # Legacy name: "organization_team"
    belongs_to :calendar, optional: true

    has_one :season_type, through: :season
    has_one :federation_type, through: :season

    # First-level children: (they "belongs_to" meeting)
    has_many :meeting_sessions, -> { order(:session_order) }, dependent: :delete_all
    has_many :swimming_pools,   through: :meeting_sessions
    has_many :pool_types,       through: :meeting_sessions
    has_many :event_types,      through: :meeting_sessions

    has_many :meeting_team_scores,        dependent: :delete_all
    has_many :meeting_reservations,       dependent: :delete_all
    has_many :meeting_event_reservations, dependent: :delete_all
    has_many :meeting_relay_reservations, dependent: :delete_all

    # Nth-level children:
    has_many :meeting_events,             through: :meeting_sessions
    has_many :meeting_programs,           through: :meeting_events
    has_many :meeting_entries,            through: :meeting_programs
    has_many :meeting_individual_results, through: :meeting_programs
    has_many :meeting_relay_results,      through: :meeting_programs
    has_many :meeting_relay_swimmers,     through: :meeting_relay_results
    has_many :laps,                       through: :meeting_programs
    has_many :category_types,             through: :meeting_programs

    # TODO: (FIX)
    # belongs_to :individual_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'individual_score_computation_type_id'
    # belongs_to :relay_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'relay_score_computation_type_id'
    # belongs_to :team_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'team_score_computation_type_id'
    # belongs_to :meeting_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'meeting_score_computation_type_id'

    acts_as_taggable_on :tags_by_users
    acts_as_taggable_on :tags_by_teams

    validates :reference_phone, length: { maximum: 40 }
    validates :reference_e_mail, length: { maximum: 50 }
    validates :reference_name, length: { maximum: 50 }
    validates :configuration_file, length: { maximum: 255 }
    validates :max_individual_events, length: { maximum: 2 }
    validates :max_individual_events_per_session, length: { maximum: 1 }

    # (For sorting scopes: see AbstractMeeting)

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Fulltext search with additional domain inclusion by using standard "LIKE"s
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      includes(:edition_type)
        .where('MATCH(meetings.description, meetings.code) AGAINST(?)', name)
        .or(includes([:edition_type]).where('meetings.description like ?', like_query))
        .or(includes([:edition_type]).where('meetings.code like ?', like_query))
        .by_date(:desc)
    }
    scope :for_team, lambda { |team|
      # Results only (not reservations or entries):
      ids = includes(:meeting_individual_results).where('meeting_individual_results.team_id': team.id).distinct.pluck(:id)
      ids << includes(:meeting_relay_results).where('meeting_relay_results.team_id': team.id).distinct.pluck(:id)
      ids.uniq!
      where(id: ids).by_date(:desc)
    }
    scope :for_swimmer, lambda { |swimmer|
      # Results only (not reservations or entries):
      ids = includes(:meeting_individual_results).where('meeting_individual_results.swimmer_id': swimmer.id).distinct.pluck(:id)
      ids << includes(:meeting_relay_swimmers).where('meeting_relay_swimmers.swimmer_id': swimmer.id).distinct.pluck(:id)
      ids.uniq!
      where(id: ids).by_date(:desc)
    }

    scope :only_manifest,   -> { where(manifest: true, results_acquired: false) } # legacy "invitation" => manifest
    scope :only_startlist,  -> { where(startlist: true, results_acquired: false) }
    scope :with_results,    -> { where(results_acquired: true) }
    scope :without_results, -> { where(results_acquired: false) }
    scope :not_closed,      -> { where(results_acquired: false).where('header_date > ?', Time.zone.today) }
    scope :still_open_at,   ->(date = Time.zone.today) { where('header_date >= ?', date).where('(entry_deadline >= ?) OR (entry_deadline IS NULL)', date) }

    # Returns +true+ if the specified +meeting+ has registered any kind of attendance or presence for the specified +team+;
    # +false+ otherwise.
    # This method checks results, reservations, entries and team scores.
    def self.team_presence?(meeting, team)
      GogglesDb::MeetingIndividualResult.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, team_id: team.id) ||
        GogglesDb::MeetingRelayResult.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, team_id: team.id) ||
        GogglesDb::MeetingTeamScore.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, team_id: team.id) ||
        GogglesDb::MeetingReservation.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, team_id: team.id) ||
        GogglesDb::MeetingEntry.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, team_id: team.id)
    end

    # Returns +true+ if the specified +meeting+ has registered any kind of attendance or presence for the specified +swimmer+;
    # +false+ otherwise.
    # This method checks results, reservations & entries.
    def self.swimmer_presence?(meeting, swimmer)
      GogglesDb::MeetingIndividualResult.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, swimmer_id: swimmer.id) ||
        GogglesDb::MeetingRelaySwimmer.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, swimmer_id: swimmer.id) ||
        GogglesDb::MeetingReservation.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, swimmer_id: swimmer.id) ||
        GogglesDb::MeetingEntry.includes(:meeting).joins(:meeting).exists?('meetings.id': meeting.id, swimmer_id: swimmer.id)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[season season_type federation_type edition_type timing_type]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[meeting_sessions meeting_events]
    end
  end
end
