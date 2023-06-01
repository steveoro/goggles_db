# frozen_string_literal: true

module GogglesDb
  #
  # = Season model
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  class Season < ApplicationRecord
    self.table_name = 'seasons'

    belongs_to :season_type
    belongs_to :edition_type
    belongs_to :timing_type
    validates_associated :season_type
    validates_associated :edition_type
    validates_associated :timing_type

    default_scope { includes(:season_type, :edition_type, :timing_type) }

    has_one :federation_type, through: :season_type

    has_many :category_types, dependent: :delete_all
    has_many :badges, dependent: :delete_all
    has_many :swimmers, through: :badges
    has_many :team_affiliations, dependent: :delete_all
    has_many :teams, through: :team_affiliations

    has_many :meetings, dependent: :delete_all
    has_many :meeting_team_scores, dependent: :delete_all
    has_many :computed_season_rankings, dependent: :delete_all
    has_many :standard_timings, dependent: :delete_all
    has_many :user_workshops, dependent: :delete_all
    # has_many :goggle_cup_definitions

    validates :header_year, presence: { length: { within: 1..9 }, allow_nil: false }
    validates :edition,     presence: { length: { within: 1..3 }, allow_nil: false }
    validates :description, presence: { length: { within: 1..100 }, allow_nil: false }
    validates :begin_date,  presence: true
    validates :end_date,    presence: true

    # Sorting scopes:
    scope :by_begin_date, ->(dir = :asc) { order('seasons.begin_date': dir) }
    scope :by_end_date,   ->(dir = :asc) { order('seasons.end_date': dir) }
    # TODO: unused yet
    # scope :by_season_type, ->(dir) { order("season_types.code #{dir}, seasons.begin_date #{dir}") }

    # Filtering scopes:
    scope :for_season_type, ->(season_type) { where(season_type_id: season_type.id) }
    scope :ongoing,      -> { where(Arel.sql('begin_date IS NOT NULL AND begin_date <= curdate() AND end_date IS NOT NULL AND end_date >= curdate()')) }
    scope :ended,        -> { where(Arel.sql('end_date IS NOT NULL AND end_date < curdate()')) }
    scope :ended_before, ->(end_date) { where('end_date IS NOT NULL AND end_date < ?', end_date) }
    # TODO
    # scope :has_results,     -> { where('exists(select 1 from meetings where are_results_acquired)') }

    def self.in_range(from_date, to_date)
      where('begin_date IS NOT NULL AND begin_date <= ?', to_date)
        .where('end_date IS NOT NULL AND end_date >= ?', from_date)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Generic Season helper.
    # Returns the last Season that has been defined given its specified type;
    # +nil+ otherwise.
    #
    # == Params
    # - <tt>season_type</tt>: the filtering <tt>GogglesDb::SeasonType</tt> instance (with no defaults).
    #
    def self.last_season_by_type(season_type)
      GogglesDb::Season.joins(:season_type).includes(:season_type)
                       .for_season_type(season_type)
                       .by_begin_date.last
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns if the season has ended at a specific date; false otherwise.
    #
    # == Parameters:
    # - check_date: the date for the check
    #
    def ended?(check_date = Time.zone.today)
      end_date ? end_date < check_date : false
    end

    # Returns if the season has started at a specific date; false otherwise.
    #
    # == Parameters:
    # - check_date: the date for the check
    #
    def started?(check_date = Time.zone.today)
      begin_date ? begin_date <= check_date : false
    end

    # Returns if the season is still ongoing according to the specified date; false otherwise.
    #
    # == Parameters:
    # - check_date: the date for the check
    #
    def ongoing?(check_date = Time.zone.today)
      started?(check_date) && !ended?(check_date)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %i[season_type edition_type timing_type]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %i[category_types]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label
      )
    end
  end
end
