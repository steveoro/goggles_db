# frozen_string_literal: true

class AddCoordinatesToCities < ActiveRecord::Migration[6.0]
  def self.up
    change_table :cities do |t|
      t.column :latitude, :string, limit: 50, default: nil, null: true
      t.column :longitude, :string, limit: 50, default: nil, null: true
    end
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
