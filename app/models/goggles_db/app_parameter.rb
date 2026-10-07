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

    APP_SETTINGS_CACHE_KEY = 'goggles_db/app_parameter/app_settings'
    MAINTENANCE_CACHE_KEY  = 'goggles_db/app_parameter/maintenance'
    APP_SETTINGS_CACHE_TTL = 1.minute

    # Returns a snapshot Hash of the +:app+ settings group, served from
    # +Rails.cache+ with a short TTL, so hot request paths (per-request filters,
    # throttles) don't hit the DB on every call. Missing keys return +nil+.
    def self.cached_app_settings
      Rails.cache.fetch(APP_SETTINGS_CACHE_KEY, expires_in: APP_SETTINGS_CACHE_TTL) do
        AppParameter.config.settings(:app).value || {}
      end
    end

    # Checks the value of the maintenance flag inside the versioning parameter row.
    # The maintenance flag is typically turned on during Web/app updates that do not require a DB shutdown or restart.
    def maintenance?
      send(TOGGLE_FIELDNAME)
    end

    # Works exactly as #maintenance? but at a class level.
    # Cached for APP_SETTINGS_CACHE_TTL; the cache entry is busted by .maintenance=.
    def self.maintenance?
      Rails.cache.fetch(MAINTENANCE_CACHE_KEY, expires_in: APP_SETTINGS_CACHE_TTL) do
        AppParameter.versioning_row.maintenance?
      end
    end

    # Sets the value of the maintenance flag and busts its cache.
    def self.maintenance=(new_boolean_value)
      result = AppParameter.versioning_row.update!(TOGGLE_FIELDNAME => new_boolean_value)
      Rails.cache.delete(MAINTENANCE_CACHE_KEY)
      result
    end

    DEFAULT_MAX_ANONYMOUS_REQ = 500

    # Returns the maximum daily anonymous request count per IP before throttling.
    # Reads from the +:app+ settings group (cached); falls back to
    # +DEFAULT_MAX_ANONYMOUS_REQ+ when the setting is missing or nil.
    def self.max_anonymous_req
      value = cached_app_settings['max_anonymous_req']
      value.present? ? value.to_i : DEFAULT_MAX_ANONYMOUS_REQ
    end

    DEFAULT_MAX_BOT_REQ = 30

    # Returns the maximum daily bot-UA request count per IP before throttling.
    # Falls back to +DEFAULT_MAX_BOT_REQ+ when the setting is missing or nil.
    def self.max_bot_req
      value = cached_app_settings['max_bot_req']
      value.present? ? value.to_i : DEFAULT_MAX_BOT_REQ
    end

    DEFAULT_MAX_REQ_PER_MINUTE = 60

    # Returns the maximum burst request count per IP per minute before throttling.
    # Falls back to +DEFAULT_MAX_REQ_PER_MINUTE+ when the setting is missing or nil.
    def self.max_req_per_minute
      value = cached_app_settings['max_req_per_minute']
      value.present? ? value.to_i : DEFAULT_MAX_REQ_PER_MINUTE
    end
  end
end
