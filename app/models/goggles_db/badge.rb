# frozen_string_literal: true

module GogglesDb
  #
  # = Badge model
  #
  #   - version:  7.000
  #   - author:   Steve A.
  #
  class Badge < ApplicationRecord
    self.table_name = 'badges'

    # belongs_to :user # [Steve, 20120212] Do not validate associated user!
    belongs_to :season
    belongs_to :swimmer
    belongs_to :team
    # TODO
    # belongs_to :team_affiliation
    belongs_to :category_type
    belongs_to :entry_time_type
    # [Steve, 20130924] entry_time_type is used as a (default) user-preference for time accreditation during meeting registration.
    # It can change on a user/season basis, thus the reference is kept on the badge.

    has_one  :season_type, through: :season
    has_one  :gender_type, through: :swimmer

    validates_associated :season
    validates_associated :swimmer
    validates_associated :team
    # validates_associated :team_affiliation
    validates_associated :category_type
    validates_associated :entry_time_type

    # has_many :meeting_individual_results
    # has_many :passages
    # has_many :meetings,      through: :meeting_individual_results
    # has_many :team_managers, through: :team_affiliation
    #
    validates :number, presence: { length: { within: 1..40 }, allow_nil: false }

    # Sorting scopes:
    scope :by_season,        ->(dir = 'ASC')  { joins(:season).order("seasons.begin_date #{dir}") }
    scope :by_swimmer,       ->(dir = 'ASC')  { joins(:swimmer).order("swimmers.complete_name #{dir}") }
    scope :by_category_type, ->(dir = 'ASC')  { joins(:category_type).order("category_types.code #{dir}") }
    # TODO: unused yet
    # scope :by_team,          ->(dir = 'ASC')  { joins(:team).order("teams.name #{dir}") }
    # scope :by_user,          ->(dir)  { joins(:user).order("users.name #{dir}") }

    # Filtering scopes:
    scope :for_category_type, ->(category_type) { joins(:category_type).where(['category_types.id = ?', category_type.id]) }
    scope :for_gender_type,   ->(gender_type)   { joins(:gender_type).where(['gender_types.id = ?', gender_type.id]) }
    scope :for_season,        ->(season)        { where(season_id: season.id) }
    scope :for_team,          ->(team)          { where(team_id: team.id) }
    scope :for_swimmer,       ->(swimmer)       { where(swimmer_id: swimmer.id) }
    scope :for_year,          ->(header_year)   { joins(:season).where(['seasons.header_year = ?', header_year]) }
    scope :for_season_type,   ->(season_type)   { joins(:season_type).where(['season_types.id = ?', season_type.id]) }
    # TODO: unused yet
    # scope :for_final_rank,       ->(final_rank = 1)   { where(['final_rank = ?', final_rank]) }
    # scope :for_team_affiliation, ->(team_affiliation) { where(team_affiliation_id: team_affiliation.id) }
  end
end
