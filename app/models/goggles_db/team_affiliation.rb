# frozen_string_literal: true

module GogglesDb
  #
  # = TeamAffiliation model
  #
  #   - version:  7.000
  #   - author:   Steve A.
  #
  class TeamAffiliation < ApplicationRecord
    self.table_name = 'team_affiliations'

    # belongs_to :user # [Steve, 20120212] Do not validate associated user!
    belongs_to :team
    belongs_to :season
    validates_associated :team
    validates_associated :season

    has_one :season_type, through: :season
    has_many :badges
    # has_many :meeting_individual_results
    # has_many :team_managers

    validates :name, presence: { length: { within: 1..100, allow_nil: false } }
    validates :number, length: { maximum: 20 }

    # Sorting scopes:
    # TODO: unused yet
    # scope :by_season, ->(dir = 'ASC') { joins(:season).order("seasons.begin_date #{dir}, team_affiliations.name #{dir}") }
    # scope :by_team,   ->(dir = 'ASC') { joins(:team).order("teams.name #{dir}") }
    # scope :by_user,   ->(dir = 'ASC') { joins(:user).order("users.name #{dir}") }
  end
end
