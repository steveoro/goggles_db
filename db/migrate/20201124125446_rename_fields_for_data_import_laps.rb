# frozen_string_literal: true

class RenameFieldsForDataImportLaps < ActiveRecord::Migration[6.0]
  def change
    rename_column :data_import_laps, :breath_number, :breath_cycles
    rename_column :data_import_laps, :not_swam_kick_number, :underwater_kicks
    rename_column :data_import_laps, :not_swam_part_seconds, :underwater_seconds
    rename_column :data_import_laps, :not_swam_part_hundreds, :underwater_hundreds
  end
end
