# frozen_string_literal: true

module GogglesDb
  #
  # = Meeting model
  #
  #   - version:  7-0.3.33
  #   - author:   Steve A.
  #
  class Meeting < AbstractMeeting
    self.table_name = 'meetings'

    # Legacy name: "organization_team"
    belongs_to :home_team, optional: true, class_name: 'Team'

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

    # WIP:
    # has_many :laps,                       through: :meeting_programs
    # has_many :swimmers,                   through: :meeting_individual_results
    # has_many :teams,                      through: :meeting_individual_results
    # has_many :category_types,             through: :meeting_programs
    # has_many :meeting_relay_swimmers,     through: :meeting_relay_results

    # belongs_to :individual_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'individual_score_computation_type_id'
    # belongs_to :relay_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'relay_score_computation_type_id'
    # belongs_to :team_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'team_score_computation_type_id'
    # belongs_to :meeting_score_computation_type, class_name: 'ScoreComputationType',
    #            foreign_key: 'meeting_score_computation_type_id'

    # acts_as_taggable_on :tags_by_users
    # acts_as_taggable_on :tags_by_teams

    validates :reference_phone, length: { maximum: 40 }
    validates :reference_e_mail, length: { maximum: 50 }
    validates :reference_name, length: { maximum: 50 }
    validates :configuration_file, length: { maximum: 255 }
    validates :max_individual_events, length: { maximum: 2 }
    validates :max_individual_events_per_session, length: { maximum: 1 }

    # (For sorting scopes: see AbstractMeeting)

    # Filtering scopes:
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      includes([:edition_type])
        .where('MATCH(meetings.description, meetings.code) AGAINST(?)', name)
        .or(includes([:edition_type]).where('meetings.description like ?', like_query))
        .or(includes([:edition_type]).where('meetings.code like ?', like_query))
        .by_date(:desc)
    }

    scope :only_manifest,   -> { where(manifest: true, results_acquired: false) } # legacy "invitation" => manifest
    scope :only_startlist,  -> { where(startlist: true, results_acquired: false) }
    scope :with_results,    -> { where(results_acquired: true) }
    scope :without_results, -> { where(results_acquired: false) }
    scope :not_closed,      -> { where(results_acquired: false).where('header_date > ?', Time.zone.today) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes main associations into the typical to_json output.
    def to_json(options = nil)
      minimal_attributes.merge(
        'meeting_sessions' => meeting_sessions.map(&:minimal_attributes),
        'meeting_events' => meeting_events.map(&:minimal_attributes)
      ).to_json(options)
    end
  end
end
