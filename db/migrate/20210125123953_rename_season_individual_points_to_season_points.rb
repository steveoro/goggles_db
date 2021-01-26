# frozen_string_literal: true

class RenameSeasonIndividualPointsToSeasonPoints < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :meeting_team_scores, :season_individual_points, :season_points
  end

  def self.down
    rename_column :meeting_team_scores, :season_points, :season_individual_points
  end
end
