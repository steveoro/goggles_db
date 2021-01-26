# frozen_string_literal: true

class CreateGogglesDbApiDailyUses < ActiveRecord::Migration[6.0]
  def self.up
    create_table :api_daily_uses do |t|
      t.integer :lock_version, default: 0
      t.string :route, null: false, index: true
      t.date :day, null: false
      t.bigint :count, default: 0

      t.timestamps
    end

    add_index :api_daily_uses, %i[route day], unique: true
  end

  def self.down
    drop_table :api_daily_uses
  end
end
