# frozen_string_literal: true

class CreateAdminGrants < ActiveRecord::Migration[6.0]
  def self.up
    drop_table :admin_grants, if_exists: true
    create_table :admin_grants do |t|
      t.integer :lock_version, default: 0
      t.string :entity, null: true
      t.references :user, null: false
      t.timestamps

      t.index :entity
      t.index %w[user_id entity], unique: true
    end
  end

  def self.down
    drop_table :admin_grants
  end
end
