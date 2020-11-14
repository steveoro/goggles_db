# frozen_string_literal: true

class DropNationTypes < ActiveRecord::Migration[6.0]
  def self.up
    remove_index :nation_types, name: :index_nation_types_on_code
    drop_table :nation_types

    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => '1.34.01'
    )
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
