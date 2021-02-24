# frozen_string_literal: true

MIGRATION_BASE_CLASS = if ActiveRecord::VERSION::MAJOR >= 5
                         ActiveRecord::Migration[5.0]
                       else
                         ActiveRecord::Migration
                       end

class RailsSettingsMigration < MIGRATION_BASE_CLASS
  def self.up
    # [Steve, 20210223] Rollback previous Settings version used:
    drop_table :settings

    # Create the new one:
    create_table :settings do |t|
      t.string     :var, null: false
      t.text       :value
      t.references :target, null: false, polymorphic: true
      t.timestamps null: true
    end
    add_index :settings, %i[target_type target_id var], unique: true
  end

  def self.down
    drop_table :settings
  end
end
