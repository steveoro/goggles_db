# frozen_string_literal: true

require 'goggles_db/version'

class RenameMeetingsOrganizationTeamToHomeTeam < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :meetings, :organization_team_id, :home_team_id
    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => '1.60.01'
    )
  end

  def self.down
    rename_column :meetings, :home_team_id, :organization_team_id
    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => '1.59.01'
    )
  end
end
