# frozen_string_literal: true

class AlterPassagesToLaps < ActiveRecord::Migration[6.0]
  def self.up
    # --- Legacy table: passages
    remove_index :laps, name: :fk_passages_passage_types
    rename_column :laps, :passage_type_id, :length_in_meters
    GogglesDb::Lap.update_all('length_in_meters = length_in_meters * 25')
    add_index :laps, :length_in_meters
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
