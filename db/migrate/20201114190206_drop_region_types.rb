# frozen_string_literal: true

class DropRegionTypes < ActiveRecord::Migration[6.0]
  def self.up
    remove_foreign_key :region_types, :nation_types
    remove_index :region_types, name: :index_region_types_on_nation_type_id
    remove_index :region_types, name: :index_region_types_on_code
    remove_index :region_types, name: :index_region_types_nation_code
    drop_table :region_types
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
