# frozen_string_literal: true

class RenameMeetingIndividualPointsForTeamScores < ActiveRecord::Migration[6.0]
  def change
    rename_column :meeting_team_scores, :season_individual_points, :season_points
  end
end
