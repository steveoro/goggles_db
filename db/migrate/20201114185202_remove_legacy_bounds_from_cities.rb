# frozen_string_literal: true

class RemoveLegacyBoundsFromCities < ActiveRecord::Migration[6.0]
  def self.up
    remove_index :cities, name: :index_cities_on_zip
    remove_index :cities, name: :idx_cities_user
    remove_column :cities, :user_id

    remove_foreign_key :cities, :area_types
    remove_column :cities, :area_type_id

    add_index :cities, %i[country_code area name], unique: true
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
