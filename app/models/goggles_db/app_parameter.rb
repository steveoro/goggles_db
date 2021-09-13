# frozen_string_literal: true

module GogglesDb
  #
  # = AppParameter model
  #
  #   - version:  7-0.3.25
  #   - author:   Steve A.
  #
  class AppParameter < ApplicationRecord
    self.table_name = 'app_parameters'

    VERSIONING_CODE = 1

    FULL_VERSION_FIELDNAME = 'a_name'
    DB_VERSION_FIELDNAME   = 'a_string'
    TOGGLE_FIELDNAME       = 'a_bool'
    SETTINGS_GROUPS        = %i[framework_urls framework_emails social_urls app].freeze

    # These shall be serialized only for +#versioning_row+:
    has_settings :framework_urls, :framework_emails, :social_urls, :app

    # Retrieves the "versioning" parameter row
    def self.versioning_row
      record = find_by(code: VERSIONING_CODE)
      raise "Missing required parameter row with code #{VERSIONING_CODE}" if record.blank?

      record
    end

    # Retrieves a copy of the configuration row that stores the setting objects
    # (with eager loading).
    #
    # The returned row can be used to access directly the settings (see below).
    #
    # == Available Settings groups:
    # - :framework_urls   => api, main, admin, chrono
    # - :framework_emails => contact, admin, admin2, devops
    # - :social_urls      => facebook, linkedin, twitter
    #
    # == Read Settings inside a group:
    # For example, for framework_emails:
    #
    #   > AppParameter.config.settings(:framework_emails).contact
    #
    # == Update Settings inside a group:
    # Again, for framework_emails:
    #
    #   > AppParameter.config.settings(:framework_emails).update!(contact: 'whatever@example.com')
    #
    # Don't use individual setters (a simple "=") for multiple edits directly on this
    # helper, unless you store a copy of the returned 'config' row before hand, otherwise
    # the #versioning_row finder will forfait your changes on the next assignation before the
    # final save! call.
    #
    # To simply change multiple settings, use a multi-column update like this:
    #
    #   > AppParameter.config.settings(:framework_emails)
    #       .update!(contact: 'whatever@example.com', admin1: 'whatever1@example.com'
    #                admin2: 'whatever2@example.com', ...)
    #
    def self.config
      includes(:setting_objects).versioning_row
    end

    # Checks the value of the maintenance flag inside the versioning parameter row.
    # The maintenance flag is typically turned on during Web/app updates that do not require a DB shutdown or restart.
    def maintenance?
      send(TOGGLE_FIELDNAME)
    end

    # Works exactly as #maintenance? but at a class level.
    def self.maintenance?
      AppParameter.versioning_row.maintenance?
    end

    # Sets the value of the maintenance flag.
    def self.maintenance=(new_boolean_value)
      AppParameter.versioning_row.update!(TOGGLE_FIELDNAME => new_boolean_value)
    end
  end
end
