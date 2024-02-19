# frozen_string_literal: true

module GogglesDb
  #
  # = Badge model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class Badge < ApplicationRecord
    self.table_name = 'badges'

    belongs_to :swimmer
    belongs_to :team_affiliation
    belongs_to :season
    belongs_to :team
    belongs_to :category_type
    belongs_to :entry_time_type
    # [Steve, 20130924] entry_time_type is used as a (default) user-preference for time accreditation during meeting registration.
    # It can change on a user/season basis, thus the reference is kept on the badge.

    has_one  :season_type, through: :season
    has_one  :gender_type, through: :swimmer

    validates_associated :swimmer
    validates_associated :team_affiliation
    validates_associated :season
    validates_associated :team
    validates_associated :category_type
    validates_associated :entry_time_type

    default_scope do
      includes(
        :swimmer, :gender_type, :team, :season, :season_type,
        :team_affiliation, :category_type, :entry_time_type
      )
    end

    # TODO: unused yet
    # has_many :meeting_individual_results
    # has_many :laps
    # has_many :meetings,      through: :meeting_individual_results
    has_many :managed_affiliations, through: :team_affiliation

    validates :number, presence: { length: { within: 1..40 }, allow_nil: false }
    validates :off_gogglecup, inclusion: { in: [true, false] }
    validates :fees_due, inclusion: { in: [true, false] }
    validates :badge_due, inclusion: { in: [true, false] }
    validates :relays_due, inclusion: { in: [true, false] }

    delegate :header_year, to: :season

    # Sorting scopes:
    scope :by_season,        ->(dir = :asc)  { joins(:season).order('seasons.begin_date': dir) }
    scope :by_swimmer,       ->(dir = :asc)  { joins(:swimmer).order('swimmers.complete_name': dir) }
    scope :by_category_type, ->(dir = :asc)  { joins(:category_type).order('category_types.code': dir) }
    # TODO: unused yet
    # scope :by_team,          ->(dir = :asc)  { joins(:team).order('teams.name': dir) }

    # Filtering scopes:
    scope :for_category_type, ->(category_type) { joins(:category_type).where('category_types.id': category_type.id) }
    scope :for_gender_type,   ->(gender_type)   { joins(:gender_type).where('gender_types.id': gender_type.id) }
    scope :for_season_type,   ->(season_type)   { joins(:season_type).where('season_types.id': season_type.id) }
    scope :for_season,        ->(season)        { where(season_id: season.id) }
    scope :for_team,          ->(team)          { where(team_id: team.id) }
    scope :for_swimmer,       ->(swimmer)       { where(swimmer_id: swimmer.id) }

    scope :for_years, lambda { |*year_list|
      condition = year_list.inject([]) { |memo, _e| memo << '(INSTR(seasons.header_year, ?) > 0)' }.join(' OR ')
      joins(:season).where(condition, *year_list)
    }

    scope :for_year, lambda { |header_year|
      joins(:season).where('(INSTR(seasons.header_year, ?) > 0)', header_year)
    }

    # TODO: unused yet
    # scope :for_final_rank,       ->(final_rank = 1)   { where(['final_rank = ?', final_rank]) }
    # scope :for_team_affiliation, ->(team_affiliation) { where(team_affiliation_id: team_affiliation.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label(locale),
        'short_label' => decorate.short_label
      )
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Swimmer
    # associated to this row.
    def swimmer_attributes
      {
        'id' => swimmer.id,
        'display_label' => swimmer.decorate.display_label,
        'short_label' => swimmer.decorate.short_label,
        'complete_name' => swimmer.complete_name,
        'last_name' => swimmer.last_name,
        'first_name' => swimmer.first_name,
        'year_of_birth' => swimmer.year_of_birth,
        'year_guessed' => swimmer.year_guessed
      }
    end
  end
end
