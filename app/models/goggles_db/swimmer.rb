# frozen_string_literal: true

module GogglesDb
  #
  # = Swimmer model
  #
  # - version:  7-0.7.09
  # - author:   Steve A.
  #
  class Swimmer < ApplicationRecord
    self.table_name = 'swimmers'

    # Actual User row associated with this Swimmer. It can be nil.
    belongs_to :associated_user, class_name: 'User', optional: true,
                                 inverse_of: :swimmer

    belongs_to            :gender_type
    validates_associated  :gender_type

    default_scope { includes(:gender_type) }

    has_many :badges, dependent: :delete_all
    has_many :team_affiliations, through: :badges
    has_many :teams,             through: :badges
    has_many :category_types,    through: :badges
    has_many :seasons,           through: :badges
    has_many :season_types,      through: :badges

    has_many :meeting_entries, dependent: :delete_all
    has_many :meeting_individual_results, dependent: :delete_all
    has_many :laps, dependent: :delete_all
    has_many :meeting_relay_swimmers, dependent: :delete_all
    has_many :meeting_relay_results, through: :meeting_relay_swimmers
    has_many :user_results, dependent: :delete_all
    has_many :user_laps, dependent: :delete_all

    validates :complete_name, presence: { length: { within: 1..100, allow_nil: false } }
    validates :last_name, length: { maximum: 50 }
    validates :first_name, length: { maximum: 50 }
    validates :year_of_birth, presence: { length: { within: 2..4, allow_nil: false } }, numericality: true
    validates :year_guessed, inclusion: { in: [true, false] }

    delegate :male?, :female?, :intermixed?, to: :gender_type

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Fulltext search with additional domain inclusion by using standard "LIKE"s
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      # NOTE: Avoid/don't use:
      # 1. "MATCH(swimmers.complete_name)" => yields too many different results for short names
      # 2. 'CONCAT(swimmers.first_name, swimmers.last_name) LIKE ?' => doesn't work well
      # 3. order(:last_name) or (:complete_name) => alters the result list moving best matches away from the top
      where('swimmers.complete_name LIKE ?', like_query)
        .or(where('MATCH(swimmers.last_name) AGAINST(?)', name))
        .or(where('swimmers.last_name LIKE ?', like_query))
    }
    scope :for_first_name,    ->(name) { where('swimmers.first_name like ?', "%#{name}%") }
    scope :for_last_name,     ->(name) { where('swimmers.last_name like ?', "%#{name}%") }
    scope :for_complete_name, ->(name) { where('MATCH(swimmers.complete_name) AGAINST(?)', name) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns the swimmer age (as a numeric value) for a given +date+.
    #
    # == Params
    # - <tt>date</tt>: the date for which the age must be computed; default: +today+.
    def age(date = Time.zone.today)
      date.year - year_of_birth
    end

    # Returns the array list of all the distinct team IDs associated
    # to the object row through the available Badges.
    # Returns an empty array when nothing is found.
    #
    # The result is memoized on the current instance (reload the instance to refresh).
    def associated_team_ids
      @associated_team_ids ||= GogglesDb::Badge.for_swimmer(self).distinct(:team_id).pluck(:team_id)
    end

    # Returns the ActiveRecord Team association of teams that have a badge belonging to this Swimmer.
    # Returns an empty association when nothing is found.
    #
    # The result is memoized on the current instance (reload the instance to refresh).
    def associated_teams
      @associated_teams ||= GogglesDb::Team.where(id: associated_team_ids)
    end

    # Returns the last category type code found given for this swimmer,
    # assuming at least 1 associated badge exists.
    #
    # The result is memoized on the current instance (reload the instance to refresh).
    #
    def last_category_type_by_badge
      @last_category_type_by_badge ||= GogglesDb::Badge.for_swimmer(self).by_season
                                                       .includes(:category_type)
                                                       .last&.category_type
    end

    # Returns the latest available (defined) <tt>CategoryType</tt> for the given <tt>SeasonType</tt>,
    # regardless the actual existence of a badge for this swimmer.
    # Only <tt>CategoryType</tt> for individuals are taken into consideration.
    #
    # == Params
    # - <tt>season_type</tt>: chosen <tt>GogglesDb::SeasonType</tt>; default: +mas_fin+.
    #
    def latest_category_type(season_type = GogglesDb::SeasonType.mas_fin)
      # Retrieve the last available FIN Season that *includes* a CategoryType which has
      # the swimmer age in range:
      last_fin_season = GogglesDb::Season.joins(:category_types)
                                         .for_season_type(season_type)
                                         .where('(age_end >= ?) AND (age_begin <= ?)', age, age)
                                         .last
      return nil unless last_fin_season

      # Use the "full" FIN season to get the actual (first) available type code for the category:
      GogglesDb::CategoryType.for_season(last_fin_season)
                             .where('(age_end >= ?) AND (age_begin <= ?)', age, age)
                             .individuals
                             .first
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[associated_user gender_type]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'long_label' => decorate.display_label(locale), # Alias, only for Swimmer
        'display_label' => decorate.display_label(locale),
        'short_label' => decorate.short_label,
        'gender_code' => gender_type.code,
        'associated_user_label' => associated_user&.decorate&.short_label
      )
    end
  end
end
