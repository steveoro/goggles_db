# frozen_string_literal: true

class RenameBoolFieldsForMeventsPlusMore < ActiveRecord::Migration[6.0]
  def change
    rename_column :meeting_events, :has_separate_gender_start_list, :split_gender_start_list
    rename_column :meeting_events, :has_separate_category_start_list, :split_category_start_list

    rename_column :data_import_meetings, :under_25_admitted, :allows_under_25
    rename_column :data_import_meetings, :start_list, :startlist
    rename_column :data_import_meetings, :out_of_season, :off_season

    rename_column :meetings, :under_25_admitted, :allows_under_25
    rename_column :meetings, :start_list, :startlist
    rename_column :meetings, :out_of_season, :off_season

    rename_column :meetings, :fb_posted, :posted
    rename_column :meetings, :pb_scanned, :pb_acquired
    rename_column :meetings, :do_not_update, :read_only
  end
end
