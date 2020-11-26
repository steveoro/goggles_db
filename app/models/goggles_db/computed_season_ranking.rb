# frozen_string_literal: true

module GogglesDb
  #
  # = ComputedSeasonRanking model
  #
  # Typically, in previous versions, this entity stored just the _final team rankings_
  # for a completely ended Season.
  #
  # We aim at reducing real-time computations by providing this serialization space for
  # any hall-of-fame-alike season history & data even for ongoing Seasons (to be updated
  # after each Meeting results acquisition).
  #
  #   - version:  7.035
  #   - authors:  Leega, Steve A.
  #
  class ComputedSeasonRanking < ApplicationRecord
    self.table_name = 'computed_season_rankings'

    belongs_to :team
    belongs_to :season
    validates_associated :team
    validates_associated :season

    validates :rank, presence: { numericality: true }
    validates :total_points, presence: { numericality: true }

    # Sorting scopes:
    scope :by_rank, ->(dir = :asc) { order(rank: dir) }

    # Filtering scopes:
    scope :for_season, ->(season) { where(season_id: season.id) }
    scope :for_team,   ->(team)   { where(team_id: team.id) }

    delegate :name,        to: :team,   prefix: true
    delegate :description, to: :season, prefix: true
    #-- ------------------------------------------------------------------------
    #++

    # Override: include all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'team' => team.attributes,
        'season' => season.attributes
      ).to_json(options)
    end
  end
end
