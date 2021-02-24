# frozen_string_literal: true

module GogglesDb
  #
  # = AppParameter model
  #
  #   - version:  7.78
  #   - author:   Steve A.
  #
  class AppParameter < ApplicationRecord
    self.table_name = 'app_parameters'

    VERSIONING_CODE = 1

    FULL_VERSION_FIELDNAME = 'a_name'
    DB_VERSION_FIELDNAME = 'a_string'
    TOGGLE_FIELDNAME     = 'a_bool'

    # These shall be serialized only for +#versioning_row+:
    has_settings :framework_urls, :framework_emails, :social_urls

    # Retrieves the "versioning" parameter row
    def self.versioning_row
      record = find_by(code: VERSIONING_CODE)
      raise "Missing required parameter row with code #{VERSIONING_CODE}" unless record.present?

      record
    end

    # Retrieves the configuration row that stores the setting objects
    # (with eager loading).
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
