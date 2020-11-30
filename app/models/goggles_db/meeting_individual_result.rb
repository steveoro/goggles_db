# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = MeetingIndividualResult model
  #
  #   - version:  7.036
  #   - author:   Steve A.
  #
  class MeetingIndividualResult < ApplicationRecord
    self.table_name = 'meeting_individual_results'
    include TimingManageable

    belongs_to :meeting_program
    validates_associated :meeting_program

    has_one :season,          through: :meeting_program
    has_one :season_type,     through: :season
    has_one :meeting_session, through: :meeting_program
    has_one :meeting,         through: :meeting_program
    has_one :meeting_event,   through: :meeting_program

    has_one :pool_type,       through: :meeting_program
    has_one :event_type,      through: :meeting_event
    has_one :category_type,   through: :meeting_program
    has_one :gender_type,     through: :meeting_program
    has_one :federation_type, through: :season_type
    has_one :stroke_type,     through: :event_type

    has_many :laps, -> { order('laps.length_in_meters') }

    # These reference fields may be filled-in later (thus not validated upon creation):
    belongs_to :team_affiliation, optional: true
    belongs_to :team,             optional: true
    belongs_to :badge,            optional: true
    belongs_to :swimmer,          optional: true
    belongs_to :disqualification_code_type, optional: true

    validates :rank, presence: { length: { within: 1..4, allow_nil: false } },
                     numericality: true

    validates :standard_points,           presence: true, numericality: true
    validates :meeting_individual_points, presence: true, numericality: true
    validates :goggle_cup_points,         presence: true, numericality: true
    validates :team_points,               presence: true, numericality: true
    validates :reaction_time,             presence: true, numericality: true

    # Sorting scopes:
    # TODO: CLEAR UNUSED
    # scope :by_meeting, ->(dir){ order("meeting_programs.meeting_session_id #{dir}, swimmers.last_name #{dir}, swimmers.first_name #{dir}") }
    # scope :by_swimmer, ->(dir = :asc) { joins(:swimmer).order("swimmers.complete_name #{dir}, meeting_individual_results.rank #{dir}") }
    # scope :by_team,    ->(dir = :asc) { joins(:team, :swimmer).order("teams.name #{dir}, swimmers.complete_name #{dir}") }
    # scope :by_badge,   ->(dir = :asc) { joins(:badge).order("badges.number #{dir}") }
    # scope :by_timing,  ->(dir = :asc)
    #      { order(disqualified: :asc, minutes: dir.to_s.downcase.to_sym,
    #        seconds: dir.to_s.downcase.to_sym, hundreds: dir.to_s.downcase.to_sym) }
    # scope :by_rank,    ->(dir = :asc) { order(disqualified: :asc, rank: dir.to_s.downcase.to_sym) }
    # scope :by_date,    ->(dir = :asc) { joins(:meeting_session).order("meeting_sessions.scheduled_date #{dir}") }
    # scope :by_goggle_cup,      ->(dir = 'DESC') { order(goggle_cup_points: dir.to_s.downcase.to_sym) }
    # scope :by_standard_points, ->(dir = 'DESC') { order(standard_points: dir.to_s.downcase.to_sym) }

    # scope :by_pool_and_event,
    #       ->(dir = :asc) { joins(:event_type, :pool_type).order("pool_types.length_in_meters #{dir}, event_types.style_order #{dir}") }
    # scope :by_gender_and_category,
    #       ->(dir = :asc) { joins(:gender_type, :category_type).order("gender_types.code #{dir}, category_types.code #{dir}") }
    # scope :by_updated_at,          ->(dir = :asc) { order(updated_at: dir) }

    # scope :by_event_order,         lambda { |dir = :asc|
    #   joins(:meeting_program, :meeting_event, :meeting_session)
    #     .includes(:meeting_event, :meeting_session)
    #     .order('meeting_sessions.session_order': dir, 'meeting_events.event_order' :dir)
    # }
    # scope :event_and_timing, lambda { |dir = :asc|
    #   joins(:meeting_program, :meeting_event, :meeting_session)
    #     .includes(:meeting_event, :meeting_session)
    #     .order('meeting_sessions.session_order': dir, 'meeting_events.event_order' :dir, :disqualified, :minutes, :seconds, :hundreds)
    # }

    # Filtering scopes:
    scope :valid_for_ranking, -> { where(out_of_race: false, disqualified: false) }
    scope :qualifications,    -> { where(disqualified: false) }
    scope :disqualifications, -> { where(disqualified: true) }
    scope :personal_bests,    -> { where(personal_best: true) }
    scope :for_gender_type,   ->(gender_type) { joins(:gender_type).where('gender_types.id': gender_type.id) }
    # TODO: CLEAR UNUSED
    # scope :with_rank,         ->(rank_filter) { where(rank: rank_filter) }
    # scope :with_score,        ->(score_sym = 'standard_points') { where("#{score_sym} > 0") }
    # # [Steve, 20180613] Do not change the scope below with a composite check on each field joined by 'AND's, because it does not work
    # scope :with_timing,              -> { where('(minutes + seconds + hundreds > 0)') }
    # scope :season_type_bests,        -> { where(season_type_best: true) }
    # scope :for_pool_type,            ->(pool_type)            { joins(:pool_type).where(['pool_types.id = ?', pool_type.id]) }
    # scope :for_season_type,          ->(season_type)          { joins(:season_type).where(['season_types.id = ?', season_type.id]) }
    # scope :for_team,                 ->(team)                 { where(team_id: team.id) }
    # scope :for_category_type,        ->(category_type)        { joins(:category_type).where(['category_types.id = ?', category_type.id]) }
    # scope :for_event_type,           ->(event_type)           { joins(:event_type).where(['event_types.id = ?', event_type.id]) }
    # scope :for_swimmer,              ->(swimmer)              { where(swimmer_id: swimmer.id) }
    # scope :for_category_code,        ->(category_code)        { joins(:category_type).where(['category_types.code = ?', category_code]) }
    # scope :for_date_range,           ->(date_begin, date_end) { joins(:meeting).where(['meetings.header_date between ? and ?', date_begin, date_end]) }
    # scope :for_season,               ->(season)               { joins(:season).where(['seasons.id = ?', season.id]) }
    # scope :for_closed_seasons,       -> { joins(:season).where('seasons.end_date is not null and seasons.end_date < curdate()') }
    # scope :for_over_that_score,      ->(score_sym = 'standard_points', points = 800) { where("#{score_sym} > #{points}") }
    # scope :for_meeting_editions,     ->(meeting) { joins(:meeting).where(['meetings.code = ?', meeting.code]) }

    # scope :for_event_by_pool_type, lambda { |event_by_pool_type|
    #   joins(:event_type, :pool_type)
    #     .where(
    #       [
    #         'event_types.id = ? AND pool_types.id = ?',
    #         event_by_pool_type.event_type_id, event_by_pool_type.pool_type_id
    #       ]
    #     )
    # }

    # scope :for_team_best, lambda { |pool_type, gender_type, category_code, event_type|
    #   joins(meeting_program: [:category_type, :meeting_event])
    #     .where(
    #       [
    #         'meeting_programs.pool_type_id = ? AND meeting_programs.gender_type_id = ? AND ' \
    #         'category_types.id = ? AND meeting_events.event_type_id = ?',
    #         pool_type.id, gender_type.id,
    #         category_type.id, event_type.id
    #       ]
    #     )
    # }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this result can be scored into the overall ranking.
    def valid_for_ranking?
      !out_of_race? && !disqualified?
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
        'meeting_program' => meeting_program.attributes,
        'pool_type' => pool_type.attributes,
        'event_type' => event_type.attributes,
        'category_type' => category_type.attributes,
        'gender_type' => gender_type.attributes,
        'stroke_type' => stroke_type.attributes,
        'laps' => laps&.map(&:attributes) # (Optional)
      ).to_json(options)
    end
  end
end
