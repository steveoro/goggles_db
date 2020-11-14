# frozen_string_literal: true

class DropAreaTypes < ActiveRecord::Migration[6.0]
  def self.up
    remove_foreign_key :area_types, :region_types
    remove_index :area_types, name: :index_area_types_on_region_type_id
    remove_index :area_types, name: :index_area_types_on_code
    remove_index :area_types, name: :index_area_types_region_code
    drop_table :area_types
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
