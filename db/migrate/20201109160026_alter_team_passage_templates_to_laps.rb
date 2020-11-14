# frozen_string_literal: true

class AlterTeamPassageTemplatesToLaps < ActiveRecord::Migration[6.0]
  def self.up
    # --- Legacy table: team_passage_templates
    remove_index :team_lap_templates, name: :idx_team_passage_templates_passage_type
    rename_column :team_lap_templates, :passage_type_id, :length_in_meters
    GogglesDb::TeamLapTemplate.update_all('length_in_meters = length_in_meters * 25')
    add_index :team_lap_templates, :length_in_meters
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
