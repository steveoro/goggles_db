# frozen_string_literal: true

class RenameHundredsToHundredths < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :goggle_cup_standards, :hundreds, :hundredths
    rename_column :individual_records, :hundreds, :hundredths

    rename_column :laps, :hundreds, :hundredths
    rename_column :laps, :underwater_hundreds, :underwater_hundredths
    rename_column :laps, :hundreds_from_start, :hundredths_from_start

    rename_column :meeting_entries, :hundreds, :hundredths
    rename_column :meeting_event_reservations, :hundreds, :hundredths
    rename_column :meeting_individual_results, :hundreds, :hundredths
    rename_column :meeting_relay_results, :hundreds, :hundredths
    rename_column :meeting_relay_results, :entry_hundreds, :entry_hundredths
    rename_column :meeting_relay_swimmers, :hundreds, :hundredths

    rename_column :season_personal_standards, :hundreds, :hundredths
    rename_column :standard_timings, :hundreds, :hundredths
    rename_column :user_results, :hundreds, :hundredths
  end

  def self.down
    # Useless to go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
