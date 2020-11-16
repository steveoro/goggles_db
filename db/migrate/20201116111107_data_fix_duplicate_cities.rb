# frozen_string_literal: true

class DataFixDuplicateCities < ActiveRecord::Migration[6.0]
  def self.up
    # Bind existing entities to original correct rows:
    # Bastia: 102 |=> 96
    GogglesDb::Team.where(city_id: 102).update_all(city_id: 96)
    GogglesDb::SwimmingPool.where(city_id: 102).update_all(city_id: 96)
    execute <<-SQL
      UPDATE data_import_teams SET city_id = 96 WHERE city_id = 102;
    SQL

    # San Dona' di Piave: 146 |=> 115
    GogglesDb::Team.where(city_id: 146).update_all(city_id: 115)
    GogglesDb::SwimmingPool.where(city_id: 146).update_all(city_id: 115)
    execute <<-SQL
      UPDATE data_import_teams SET city_id = 115 WHERE city_id = 146;
    SQL

    # Canosa di Puglia: 149 |=> 123
    GogglesDb::Team.where(city_id: 123).update_all(city_id: 149)
    GogglesDb::SwimmingPool.where(city_id: 123).update_all(city_id: 149)
    execute <<-SQL
      UPDATE data_import_teams SET city_id = 123 WHERE city_id = 149;
    SQL

    # Remove duplicates:
    GogglesDb::City.delete([102, 146, 149])

    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => '1.34.02'
    )
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
