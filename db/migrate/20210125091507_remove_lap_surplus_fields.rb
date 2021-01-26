# frozen_string_literal: true

class RemoveLapSurplusFields < ActiveRecord::Migration[6.0]
  def self.up
    remove_column :laps, :native_from_start
    remove_reference(:laps, :meeting_entry, index: true)
  end

  def self.down
    # Useless to go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
