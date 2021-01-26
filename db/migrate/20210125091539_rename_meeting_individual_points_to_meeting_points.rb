# frozen_string_literal: true

class RenameMeetingIndividualPointsToMeetingPoints < ActiveRecord::Migration[6.0]
  def change
    rename_column :meeting_individual_results, :meeting_individual_points, :meeting_points
  end
end
