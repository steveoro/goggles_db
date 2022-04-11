# frozen_string_literal: true

require 'goggles_db/version'

class AddPlusCodeForMaps < ActiveRecord::Migration[6.0]
  def self.up
    change_table :cities do |t|
      t.column :plus_code, :string, limit: 50, default: nil, null: true
    end

    change_table :swimming_pools do |t|
      t.column :latitude, :string, limit: 50, default: nil, null: true
      t.column :longitude, :string, limit: 50, default: nil, null: true
      t.column :plus_code, :string, limit: 50, default: nil, null: true
    end

    # --- Add a handful of default Plus codes:
    #     (@see https://maps.google.com/pluscodes/)
    GogglesDb::SwimmingPool.find(1).update!(plus_code: '8FPGMJQW+Q4') # RE, Melato 25
    GogglesDb::SwimmingPool.find(2).update!(plus_code: '8FPGMJQW+H2') # RE, Melato 50
    GogglesDb::SwimmingPool.find(3).update!(plus_code: '8FPGR8HM+F3') # PR, G.Onesti 25
    GogglesDb::SwimmingPool.find(4).update!(plus_code: '8FPHF8R5+VF') # BO, C.Longo 25
    # Show on map: https://plus.codes/#{plus_code}

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
