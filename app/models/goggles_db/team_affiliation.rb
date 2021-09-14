# frozen_string_literal: true

module GogglesDb
  #
  # = TeamAffiliation model
  #
  #   - version:  7-0.3.31
  #   - author:   Steve A.
  #
  class TeamAffiliation < ApplicationRecord
    self.table_name = 'team_affiliations'

    belongs_to :team
    belongs_to :season
    validates_associated :team
    validates_associated :season

    has_one :season_type, through: :season
    has_many :badges, dependent: :delete_all
    has_many :managed_affiliations, dependent: :delete_all

    validates :name, presence: { length: { within: 1..100, allow_nil: false } }
    validates :number, length: { maximum: 20 }

    delegate :header_year, to: :season

    # Sorting scopes:
    # TODO: unused yet
    # scope :by_season, ->(dir = :asc) { joins(:season).order('seasons.begin_date': dir, 'team_affiliations.name': dir) }
    # scope :by_team,   ->(dir = :asc) { joins(:team).order('teams.name': dir) }

    # Filtering scopes:
    scope :for_name,  ->(name) { where('MATCH(team_affiliations.name) AGAINST(?)', name) }

    scope :for_years, lambda { |*year_list|
      condition = year_list.inject([]) { |memo, _e| memo << '(INSTR(seasons.header_year, ?) > 0)' }.join(' OR ')
      joins(:season).where(condition, *year_list)
    }

    scope :for_year, lambda { |header_year|
      joins(:season).where('(INSTR(seasons.header_year, ?) > 0)', header_year)
    }
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
        'team' => team.minimal_attributes,
        'season' => season.minimal_attributes,
        'badges' => recent_badges([season.begin_date.year, season.end_date.year]).map(&:minimal_attributes),
        'managers' => managers
      ).to_json(options)
    end
  end
end
