# frozen_string_literal: true

class CreateGogglesDbImportQueues < ActiveRecord::Migration[6.0]
  def self.up
    create_table :import_queues do |t|
      t.integer :lock_version, default: 0
      t.references :user, null: false
      t.integer :processed_depth, default: 0, index: true
      t.integer :requested_depth, default: 0, index: true
      t.integer :solvable_depth, default: 0, index: true
      t.text :request_data, null: false
      t.text :solved_data, null: false
      t.boolean :done, null: false, default: false, index: true

      t.timestamps
    end
  end

  def self.down
    drop_table :import_queues
  end
end
