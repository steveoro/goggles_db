# frozen_string_literal: true

class RenameBoolFieldsForMrrAndLaps < ActiveRecord::Migration[6.0]
  def change
    # Leftovers from previous migration:
    rename_column :data_import_meeting_individual_results, :is_play_off, :play_off
    rename_column :data_import_meeting_individual_results, :is_out_of_race, :out_of_race
    rename_column :data_import_meeting_individual_results, :is_disqualified, :disqualified

    rename_column :data_import_meeting_relay_results, :is_play_off, :play_off
    rename_column :data_import_meeting_relay_results, :is_out_of_race, :out_of_race
    rename_column :data_import_meeting_relay_results, :is_disqualified, :disqualified
    rename_column :meeting_relay_results, :is_play_off, :play_off
    rename_column :meeting_relay_results, :is_out_of_race, :out_of_race
    rename_column :meeting_relay_results, :is_disqualified, :disqualified

    rename_column :data_import_laps, :is_native_from_start, :native_from_start
    rename_column :laps, :is_native_from_start, :native_from_start
  end
end
