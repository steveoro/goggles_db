# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = MeetingRelayResult model
  #
  #   - version:  7-0.6.21
  #   - author:   Steve A.
  #
  class MeetingRelayResult < ApplicationRecord
    self.table_name = 'meeting_relay_results'

    include TimingManageable

    belongs_to :meeting_program
    belongs_to :team
    belongs_to :team_affiliation

    validates_associated :meeting_program
    validates_associated :team
    validates_associated :team_affiliation

    belongs_to :entry_time_type, optional: true
    belongs_to :disqualification_code_type, optional: true

    has_one :season,          through: :meeting_program
    has_one :meeting,         through: :meeting_program
    has_one :meeting_session, through: :meeting_program
    has_one :meeting_event,   through: :meeting_program

    has_one :season_type,   through: :meeting_program
    has_one :pool_type,     through: :meeting_program
    has_one :event_type,    through: :meeting_program
    has_one :category_type, through: :meeting_program
    has_one :gender_type,   through: :meeting_program

    has_many :meeting_relay_swimmers, dependent: :delete_all

    has_many :relay_laps, -> { order('relay_laps.length_in_meters') },
             inverse_of: :meeting_relay_result, dependent: :delete_all

    default_scope do
      includes(
        :team, :team_affiliation,
        meeting_program: [
          :meeting,
          :category_type,
          :gender_type,
          {
            meeting_event: [:event_type],
            season: [:season_type]
          }
        ]
      )
    end

    validates :relay_code, length: { maximum: 60 }, allow_blank: true
    validates :rank, presence: { length: { within: 1..4, allow_nil: false }, numericality: true }
    validates :standard_points, presence: true, numericality: true
    validates :meeting_points, presence: true, numericality: true
    validates :reaction_time, presence: true, numericality: true

    delegate :length_in_meters, :phase_length_in_meters, :phases, to: :event_type, prefix: false

    # Sorting scopes:
    scope :by_rank, -> { order(disqualified: :asc, standard_points: :desc, meeting_points: :desc, rank: :asc) }
    scope :by_timing, lambda { |dir = :asc|
      order(
        disqualified: :asc,
        Arel.sql('minutes * 6000 + seconds * 100 + hundredths') => dir.to_s.downcase.to_sym
      )
    }
    # TODO: CLEAR UNUSED / add more only if really needed
    # scope :by_split_category, ->(dir = :asc) { joins(:category_type, :gender_type).order('gender_types.code': :desc, 'category_types.code': dir) }
    # scope :by_meeting_relay, ->(dir)         { order("meeting_program_id #{dir}, rank #{dir}") }

    # Filtering scopes:
    scope :valid_for_ranking, -> { where(out_of_race: false, disqualified: false) }
    scope :qualifications,    -> { where(disqualified: false) }
    scope :disqualifications, -> { where(disqualified: true) }

    scope :for_team, ->(team) { where(team_id: team.id) }
    scope :for_rank, ->(rank_filter) { where(rank: rank_filter) }

    scope :with_rank,    -> { where('rank > 0') } # any positive rank => qualified
    scope :with_no_rank, -> { where('(rank = 0) OR (rank IS NULL)') }
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundredths > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundredths: 0) }

    # TODO: CLEAR UNUSED
    # scope :with_score,        ->(score_sym = 'standard_points') { where("#{score_sym} > 0") }
    # scope :for_over_that_score, ->(score_sym = 'standard_points', points = 800) { where("#{score_sym} > #{points}") }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this result can be scored into the overall ranking.
    def valid_for_ranking?
      !out_of_race? && !disqualified?
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s,
        'team_name' => team.editable_name,
        'team_label' => team.decorate.display_label,
        'event_label' => event_type.label(locale),
        'category_label' => category_type.decorate.short_label,
        'category_code' => category_type.code,
        'gender_code' => gender_type.code
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

    # AbstractResult overrides:
    alias_attribute :parent_meeting, :meeting # (old, new)
  end
end
