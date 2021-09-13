# frozen_string_literal: true

require 'goggles_db/version'

class PurgeOldUserData < ActiveRecord::Migration[6.0]
  def self.up
    Rails.logger.debug "\r\n--> Destroing all users except first 4 (tot.: 671)..."
    GogglesDb::User.where('id > 4').destroy_all
    Rails.logger.debug 'Done.'

    # --- Update DB structure versioning:
    GogglesDb::AppParameter.versioning_row.update(
      GogglesDb::AppParameter::FULL_VERSION_FIELDNAME => GogglesDb::Version::FULL,
      GogglesDb::AppParameter::DB_VERSION_FIELDNAME => GogglesDb::Version::DB
    )
  end

  def self.down
    # Can't go back to old data after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
