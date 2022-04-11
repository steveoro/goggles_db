# frozen_string_literal: true

require 'goggles_db/version'

class FixCanosadipugliaSwimmingPools < ActiveRecord::Migration[6.0]
  def self.up
    # Base seed data for SwimmingPools & Cities is equal among the 3 DB dumps,
    # so this migration can be applied safely to any environment.

    # Both rows must point to the correct City.id to be valid; row 149 has been deleted
    # by a previous data normalization.
    GogglesDb::SwimmingPool.where(id: [140, 181]).update_all(city_id: 123)

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
