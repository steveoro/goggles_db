# frozen_string_literal: true

require 'goggles_db/version'

class UpdateDbVersionTo158 < ActiveRecord::Migration[6.0]
  def self.up
    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => GogglesDb::Version::DB
    )
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
