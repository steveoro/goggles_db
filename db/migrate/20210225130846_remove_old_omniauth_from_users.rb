# frozen_string_literal: true

class RemoveOldOmniauthFromUsers < ActiveRecord::Migration[6.0]
  def self.up
    remove_column :users, :facebook_uid
    remove_column :users, :goggle_uid
    remove_column :users, :twitter_uid

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
