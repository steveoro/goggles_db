# frozen_string_literal: true

module GogglesDb
  #
  # = TeamAffiliation model
  #
  #   - version:  7.036
  #   - author:   Steve A.
  #
  class TeamAffiliation < ApplicationRecord
    self.table_name = 'team_affiliations'

    belongs_to :team
    belongs_to :season
    validates_associated :team
    validates_associated :season

    has_one :season_type, through: :season
    has_many :badges
    has_many :managed_affiliations

    validates :name, presence: { length: { within: 1..100, allow_nil: false } }
    validates :number, length: { maximum: 20 }

    delegate :header_year, to: :season

    # Sorting scopes:
    # TODO: unused yet
    # scope :by_season, ->(dir = :asc) { joins(:season).order('seasons.begin_date': dir, 'team_affiliations.name': dir) }
    # scope :by_team,   ->(dir = :asc) { joins(:team).order('teams.name': dir) }
    # scope :by_user,   ->(dir = :asc) { joins(:user).order('users.name': dir) }

    # Filtering scopes:
    scope :for_year,  ->(header_year) { joins(:season).where('seasons.header_year': header_year) }
    scope :for_years, ->(*year_list)  { joins(:season).where(['seasons.header_year IN (?)', year_list]) }
    #-- ------------------------------------------------------------------------
    #++

    # Instance scope helper for recent badges, given a list of years
    def recent_badges(year_list = [Time.zone.today.year - 1, Time.zone.today.year])
      badges.for_years(*year_list)
    end

    # Returns the array of Team Managers (GogglesDb::User) associated to this affiliation
    def managers
      managed_affiliations.map(&:manager)
    end

    # Override: includes *most* of its 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'team' => team.attributes,
        'season' => season.attributes,
        'badges' => recent_badges.map(&:attributes),
        'managers' => managers
      ).to_json(options)
    end
  end
end
