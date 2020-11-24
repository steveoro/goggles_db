# frozen_string_literal: true

class RenameFieldsForLaps < ActiveRecord::Migration[6.0]
  def change
    rename_column :laps, :breath_number, :breath_cycles
    rename_column :laps, :not_swam_kick_number, :underwater_kicks
    rename_column :laps, :not_swam_part_seconds, :underwater_seconds
    rename_column :laps, :not_swam_part_hundreds, :underwater_hundreds
  end
end
