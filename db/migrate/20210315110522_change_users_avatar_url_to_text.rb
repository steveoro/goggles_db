# frozen_string_literal: true

require 'goggles_db/version'

class ChangeUsersAvatarUrlToText < ActiveRecord::Migration[6.0]
  def self.up
    change_column :users, :avatar_url, :text

    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => GogglesDb::Version::DB
    )
  end

  def self.down
    # Can't go back to old structure after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
