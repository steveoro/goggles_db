# frozen_string_literal: true

class AddTwitterProviderToUsers < ActiveRecord::Migration[6.0]
  def self.up
    remove_column :users, :use_email_data_updates_notify
    remove_column :users, :use_email_achievements_notify
    remove_column :users, :use_email_newsletter_notify
    remove_column :users, :use_email_community_notify

    rename_column :users, :avatar_resource_filename, :avatar_url
    rename_column :users, :authentication_token, :jwt

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
