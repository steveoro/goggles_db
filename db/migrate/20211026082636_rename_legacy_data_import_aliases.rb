# frozen_string_literal: true

class RenameLegacyDataImportAliases < ActiveRecord::Migration[6.0]
  def self.up
    rename_table(:data_import_swimmer_aliases, :swimmer_aliases)
    rename_table(:data_import_team_aliases, :team_aliases)
  end

  def self.down
    rename_table(:swimmer_aliases, :data_import_swimmer_aliases)
    rename_table(:team_aliases, :data_import_team_aliases)
  end
end
