# frozen_string_literal: true

class AlterDataImportPassagesToLaps < ActiveRecord::Migration[6.0]
  def self.up
    # [Steve A.]
    # All legacy lap_types rows had a value length of precisely ID*25 mt..
    # We're now going to compute'em all in real time and getting rid of the old table.

    # --- Legacy table: data_import_passages
    rename_table :data_import_passages, :data_import_laps
    remove_index :data_import_laps, name: :idx_di_passages_passage_type
    rename_column :data_import_laps, :passage_type_id, :length_in_meters
    # DataImportLaps model is still WIP, so we proceed with low-level SQL here:
    execute <<-SQL.squish
      UPDATE data_import_laps SET length_in_meters = length_in_meters * 25
    SQL
    add_index :data_import_laps, :length_in_meters
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
