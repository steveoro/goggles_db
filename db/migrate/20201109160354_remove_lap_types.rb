# frozen_string_literal: true

class RemoveLapTypes < ActiveRecord::Migration[6.0]
  def self.up
    # --- Final clean-up:
    remove_index :lap_types, name: :index_lap_types_on_code
    drop_table :lap_types

    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => '1.31.30'
    )
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
