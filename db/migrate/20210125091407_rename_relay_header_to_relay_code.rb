# frozen_string_literal: true

class RenameRelayHeaderToRelayCode < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :meeting_relay_results, :relay_header, :relay_code
  end

  def self.down
    rename_column :meeting_relay_results, :relay_code, :relay_header
  end
end
