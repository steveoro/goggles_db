# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingTeamScore model
  #
  #   - version:  7.035
  #   - author:   Steve A.
  #
  # Stores the overall scoring computed for all Team results in a single Meeting.
  #
  class MeetingTeamScore < ApplicationRecord
    self.table_name = 'meeting_team_scores'

    belongs_to :team
    belongs_to :team_affiliation
    belongs_to :meeting
    belongs_to :season
    validates_associated :team
    validates_associated :team_affiliation
    validates_associated :meeting
    validates_associated :season

    validates :rank, presence: true, numericality: true
    validates :sum_individual_points, presence: true, numericality: true
    validates :sum_relay_points, presence: true, numericality: true
    validates :sum_team_points, presence: true, numericality: true
    validates :meeting_individual_points, presence: true, numericality: true
    validates :meeting_relay_points, presence: true, numericality: true
    validates :meeting_team_points, presence: true, numericality: true
    validates :season_individual_points, presence: true, numericality: true
    validates :season_relay_points, presence: true, numericality: true
    validates :season_team_points, presence: true, numericality: true

    scope :with_season_score, -> { where(Arel.sql('(season_individual_points + season_relay_points + season_team_points) > 0')) }
    scope :for_team,          ->(team)    { where(team_id: team.id) }
    scope :for_meeting,       ->(meeting) { where(meeting_id: meeting.id) }
  end
end
