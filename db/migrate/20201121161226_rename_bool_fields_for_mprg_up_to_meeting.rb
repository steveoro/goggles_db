# frozen_string_literal: true

class RenameBoolFieldsForMprgUpToMeeting < ActiveRecord::Migration[6.0]
  def change
    rename_column :data_import_meeting_programs, :is_out_of_race, :out_of_race
    rename_column :meeting_programs, :is_autofilled, :autofilled
    rename_column :meeting_programs, :is_out_of_race, :out_of_race

    rename_column :meeting_entries, :is_no_time, :no_time

    rename_column :meeting_events, :is_autofilled, :autofilled
    rename_column :meeting_events, :is_out_of_race, :out_of_race

    rename_column :meeting_event_reservations, :is_doing_this, :accepted
    rename_column :meeting_relay_reservations, :is_doing_this, :accepted
    rename_column :meeting_reservations, :is_not_coming, :not_coming
    rename_column :meeting_reservations, :has_confirmed, :confirmed

    rename_column :meeting_sessions, :is_autofilled, :autofilled

    rename_column :data_import_meetings, :has_warm_up_pool, :warm_up_pool
    rename_column :data_import_meetings, :is_under_25_admitted, :under_25_admitted
    rename_column :data_import_meetings, :has_invitation, :manifest
    rename_column :data_import_meetings, :has_start_list, :start_list
    rename_column :data_import_meetings, :are_results_acquired, :results_acquired
    rename_column :data_import_meetings, :is_out_of_season, :out_of_season

    rename_column :meetings, :has_warm_up_pool, :warm_up_pool
    rename_column :meetings, :is_under_25_admitted, :under_25_admitted
    rename_column :meetings, :invitation, :manifest_body
    rename_column :meetings, :has_invitation, :manifest
    rename_column :meetings, :has_start_list, :start_list
    rename_column :meetings, :are_results_acquired, :results_acquired
    rename_column :meetings, :is_autofilled, :autofilled
    rename_column :meetings, :is_out_of_season, :out_of_season

    rename_column :meetings, :is_confirmed, :confirmed
    rename_column :meetings, :is_tweeted, :tweeted
    rename_column :meetings, :is_fb_posted, :fb_posted
    rename_column :meetings, :is_cancelled, :cancelled
    rename_column :meetings, :is_pb_scanned, :pb_scanned
  end
end
