# frozen_string_literal: true

class RemoveLegacyUserIdReferences < ActiveRecord::Migration[6.0]
  def self.up
    remove_reference(:badges, :user, index: true)
    remove_reference(:base_movements, :user, index: true)
    remove_reference(:data_import_badges, :user, index: true)
    remove_reference(:data_import_cities, :user, index: true)
    remove_reference(:data_import_laps, :user, index: true)
    remove_reference(:data_import_meeting_entries, :user, index: true)
    remove_reference(:data_import_meeting_individual_results, :user, index: true)
    remove_reference(:data_import_meeting_programs, :user, index: true)
    remove_reference(:data_import_meeting_relay_results, :user, index: true)
    remove_reference(:data_import_meeting_relay_swimmers, :user, index: true)
    remove_reference(:data_import_meeting_sessions, :user, index: true)
    remove_reference(:data_import_meeting_team_scores, :user, index: true)
    remove_reference(:data_import_meetings, :user, index: true)
    remove_reference(:data_import_swimmers, :user, index: true)
    remove_reference(:data_import_teams, :user, index: true)
    remove_reference(:exercises, :user, index: true)
    remove_reference(:fin_calendars, :user, index: true)
    remove_reference(:goggle_cups, :user, index: true)
    remove_reference(:laps, :user, index: true)

    remove_reference(:meeting_entries, :user, index: true)
    remove_reference(:meeting_event_reservations, :user, index: true)
    remove_reference(:meeting_events, :user, index: true)
    remove_reference(:meeting_individual_results, :user, index: true)
    remove_reference(:meeting_programs, :user, index: true)
    remove_reference(:meeting_relay_reservations, :user, index: true)
    remove_reference(:meeting_relay_results, :user, index: true)
    remove_reference(:meeting_relay_swimmers, :user, index: true)
    remove_reference(:meeting_sessions, :user, index: true)
    remove_reference(:meeting_team_scores, :user, index: true)
    remove_reference(:meetings, :user, index: true)

    remove_reference(:swimmer_season_scores, :user, index: true, foreign_key: true)
    remove_reference(:swimmers, :user, index: true)
    remove_reference(:swimming_pools, :user, index: true)
    remove_reference(:team_affiliations, :user, index: true)
    remove_reference(:team_lap_templates, :user, index: true)
    remove_reference(:teams, :user, index: true)
    remove_reference(:trainings, :user, index: true)
  end

  def self.down
    # Useless to go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
