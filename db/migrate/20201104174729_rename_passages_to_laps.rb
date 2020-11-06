# frozen_string_literal: true

class RenamePassagesToLaps < ActiveRecord::Migration[6.0]
  def change
    rename_table :passages, :laps
    rename_table :passage_types, :lap_types
  end
end
