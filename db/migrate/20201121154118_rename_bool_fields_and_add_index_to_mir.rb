# frozen_string_literal: true

class RenameBoolFieldsAndAddIndexToMir < ActiveRecord::Migration[6.0]
  def change
    rename_column :meeting_individual_results, :is_play_off, :play_off
    rename_column :meeting_individual_results, :is_out_of_race, :out_of_race
    rename_column :meeting_individual_results, :is_disqualified, :disqualified
    rename_column :meeting_individual_results, :is_personal_best, :personal_best
    rename_column :meeting_individual_results, :is_season_type_best, :season_type_best

    add_index :meeting_individual_results, :out_of_race
    add_index :meeting_individual_results, :disqualified
    add_index :meeting_individual_results, :personal_best
    add_index :meeting_individual_results, :season_type_best
  end
end
