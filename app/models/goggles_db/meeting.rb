# frozen_string_literal: true

require 'extensions/roman_numeral'

module GogglesDb
  #
  # = Meeting model
  #
  #   - version:  7.034
  #   - author:   Steve A.
  #
  class Meeting < ApplicationRecord
    self.table_name = 'meetings'

    belongs_to :season
    belongs_to :edition_type
    belongs_to :timing_type

    # Legacy name: "organization_team"
    # belongs_to :home_team, optional: true, class_name: 'Team'

    validates_associated :season
    validates_associated :edition_type
    validates_associated :timing_type

    has_one :season_type, through: :season
    has_one :federation_type, through: :season

    # # First-level children: (they "belongs_to" meeting)
    has_many :meeting_sessions, -> { order(:session_order) }, dependent: :delete_all
    has_many :swimming_pools,   through: :meeting_sessions
    has_many :pool_types,       through: :meeting_sessions
    has_many :event_types,      through: :meeting_sessions

    # has_many :meeting_team_scores,        dependent: :delete_all
    # has_many :meeting_reservations,       dependent: :delete_all
    # has_many :meeting_event_reservations, dependent: :delete_all

    # # Nth-level children: (through-association with meeting)
    # has_many :meeting_events,             through: :meeting_sessions
    # has_many :meeting_programs,           through: :meeting_events
    # has_many :meeting_entries,            through: :meeting_programs
    # has_many :meeting_individual_results, through: :meeting_programs
    # has_many :meeting_relay_results,      through: :meeting_programs
    # has_many :passages,                   through: :meeting_programs

    # WIP:
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

    validates :code,        presence: { length: { within: 1..50 }, allow_nil: false }
    validates :header_year, presence: { length: { within: 1..9 }, allow_nil: false }
    validates :edition,     presence: { length: { maximum: 3 }, allow_nil: false }
    validates :description, presence: { length: { maximum: 100 }, allow_nil: false }

    validates :reference_phone, length: { maximum: 40 }
    validates :reference_e_mail, length: { maximum: 50 }
    validates :reference_name, length: { maximum: 50 }
    validates :configuration_file, length: { maximum: 255 }
    validates :max_individual_events, length: { maximum: 2 }
    validates :max_individual_events_per_session, length: { maximum: 1 }

    alias_attribute :warm_up_pool?,     :has_warm_up_pool
    alias_attribute :allows_under_25?,  :is_under_25_admitted
    alias_attribute :invitation?,       :has_invitation
    alias_attribute :startlist?,        :has_start_list
    alias_attribute :off_season?,       :is_out_of_season
    alias_attribute :confirmed?,        :is_confirmed
    alias_attribute :cancelled?,        :is_cancelled
    alias_attribute :tweeted?,          :is_tweeted     # Results acquisition tweeted
    alias_attribute :posted?,           :is_fb_posted   # Results details posted

    alias_attribute :results_acquired?, :are_results_acquired
    alias_attribute :autofilled?,       :is_autofilled
    alias_attribute :read_only?,        :do_not_update
    alias_attribute :pb_acquired?,      :is_pb_scanned  # "Personal Best" timings already acquired?

    # Sorting scopes:
    scope :by_date,   ->(dir = 'ASC')  { order(dir == 'ASC' ? 'header_date ASC' : 'header_date DESC') }
    scope :by_season, ->(dir = 'ASC')  { joins(:season).order(dir == 'ASC' ? 'seasons.begin_date ASC' : 'seasons.begin_date DESC') }

    # Filtering scopes:
    # scope :only_invitation, -> { where('has_invitation and not are_results_acquired') }
    # scope :only_start_list, -> { where('has_start_list and not are_results_acquired') }
    # scope :results,         -> { where('are_results_acquired') }
    # scope :no_results,      -> { where('not are_results_acquired') }
    # scope :not_closed,      -> { where('(not are_results_acquired) and (header_date >= curdate())') }
    # scope :not_cancelled,   -> { where('(not is_cancelled)') }
    # scope :for_season_type, ->(season_type) { joins(:season_type).where(['season_types.id = ?', season_type.id]) }
    # scope :for_code,        ->(code)        { where(['code = ?', code]) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns the verbose edition label based on the current edition value & type.
    # Returns a safe empty string otherwise.
    #
    def edition_label
      return edition.to_s if edition_type.ordinal?

      return edition.to_i.to_roman if edition_type.roman?

      return header_year if edition_type.seasonal? || edition_type.yearly?

      ''
    end

    # # Retrieves the first scheduled date for this meeting; nil when not found
    # def scheduled_date
    #   ms = meeting_sessions.sort_by_order.first
    #   ms ? Format.a_date(ms.scheduled_date) : nil
    # end

    # # Retrieves the date for this meeting.
    # # Return the first session one if set,
    # # or the general meeting scheduled date if not
    # def meeting_date
    #   scheduled_date || Format.a_date(header_date)
    # end
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes the 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'edition_label' => edition_label,
        'season' => season.attributes,
        'edition_type' => edition_type.attributes,
        'timing_type' => timing_type.attributes,
        'season_type' => season_type.attributes,
        'federation_type' => federation_type.attributes
      ).to_json(options)
    end
  end
end
