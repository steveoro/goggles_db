# frozen_string_literal: true

require 'goggles_db/version'

class DataFixCities < ActiveRecord::Migration[6.0]
  def self.up
    [
      { old: 'Monastier', new: 'Monastier Treviso' },
      { old: 'GIUGLIANO', new: 'GIUGLIANO CAMPANIA' },
      { old: 'CANOSA', new: 'CANOSA PUGLIA' },
      { old: 'PINARELLA DI CERVIA', new: 'Pinarella' },
      { old: 'LOVADINA DI SPRESIANO', new: 'Spresiano' }
    ].each do |params|
      GogglesDb::City.where(name: params[:old]).update(name: params[:new])
    end

    # Wrong localized name:
    GogglesDb::City.where(name: 'STOCCOLMA').update(name: 'Stockholm', area: 'Stockholm')

    # Totally missing from gem's database:
    #
    # "NIBIONNO" (Lecco) => MISS
    # "CALDIERO" (Verona) => MISS
    # "LUMEZZANE" (Brescia) => MISS
    #
    # [Steve A., 20201114]
    # No data for these rows in the old database (~2011) provided by the cities gem.
    # Since parsing in the new datafiles is currently too much work for my personal allotted
    # time, we'll resort to just leave these 3 records as they are, using the existing 'cities'
    # table as an integration for any other future custom name.

    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => '1.33.00'
    )
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
