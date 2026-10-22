# frozen_string_literal: true

module GogglesDb
  #
  # = Season model
  #
  #   - version:  7-0.6.30
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

    # SQL fragment computing the "championship year" of a season, identical to the
    # formula used by the best-result Scenic views and by the DB function
    # +goggles_db_base_year()+:
    # - Sep-Dec start: championship_year = YEAR(begin_date)
    # - Jun-Aug start: championship_year = YEAR(end_date)
    # - Jan-May start: championship_year = YEAR(begin_date) - 1
    CHAMPIONSHIP_YEAR_SQL = Arel.sql(
      'CASE WHEN MONTH(seasons.begin_date) >= 9 THEN YEAR(seasons.begin_date) ' \
      'WHEN MONTH(seasons.begin_date) <= 5 THEN YEAR(seasons.begin_date) - 1 ' \
      'ELSE YEAR(seasons.end_date) END'
    ).freeze

    default_scope { includes(:edition_type, :timing_type, :season_type, :federation_type) }

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

    # Returns all seasons belonging to the specified championship year(s)
    # (same definition used by the best-result views and the +goggles_db_base_year()+ function).
    scope :for_championship_year, lambda { |*years|
      year_list = years.flatten.compact.map(&:to_i).reject(&:zero?)
      year_list.present? ? where("#{CHAMPIONSHIP_YEAR_SQL} IN (?)", year_list) : none
    }

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

    # Returns the current reference championship year, as computed by the DB function
    # +goggles_db_base_year()+ (latest ongoing championship year, or the +@base_year+
    # session variable value when set). Falls back to the current calendar year when
    # no ongoing season is found.
    def self.current_championship_year
      connection.select_value('SELECT goggles_db_base_year()')&.to_i.presence || Date.current.year
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

    # Returns the "championship year" this season belongs to, using the same formula
    # as CHAMPIONSHIP_YEAR_SQL (and the best-result views / +goggles_db_base_year()+):
    # - Sep-Dec start: championship_year = YEAR(begin_date)
    # - Jun-Aug start: championship_year = YEAR(end_date)
    # - Jan-May start: championship_year = YEAR(begin_date) - 1
    # Returns +nil+ when either boundary date is missing.
    def championship_year
      return nil if begin_date.blank? || end_date.blank?
      return begin_date.year if begin_date.month >= 9
      return begin_date.year - 1 if begin_date.month <= 5

      end_date.year
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[season_type edition_type timing_type]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[category_types]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label
      )
    end
  end
end
