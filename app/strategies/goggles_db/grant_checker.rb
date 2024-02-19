# frozen_string_literal: true

module GogglesDb
  #
  # = "Grant checker" wrapper/strategy object
  #
  #   - version...: 7-0.6.30
  #   - author....: Steve A.
  #
  #   Checks if a specified User instance has either specific admin-grants for a certain
  #   entity or has generic administrative rights.
  #
  # == NOTE:
  # Prefer the instance versions of the helpers instead of the class helper methods as the class
  # helpers perform an SQL query for each call, whereas the instance version memoizes the results.
  #
  class GrantChecker
    # Constructor.
    # Retrieves all grants for the specified +user and memoizes all grants.
    #
    # === Params
    # - user: a valid GogglesDb::User instance.
    #
    def initialize(user)
      raise(ArgumentError, 'Invalid User instance specified') unless user.is_a?(GogglesDb::User)

      @user = user
      @grants = GogglesDb::AdminGrant.where(user_id: user.id).to_a
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the specified User can do anything. False otherwise.
    def self.admin?(user)
      return false unless user.is_a?(GogglesDb::User)

      GogglesDb::AdminGrant.exists?(user_id: user.id, entity: nil)
    end

    # Returns +true+ if the specified User can do anything on the specified entity.
    def self.crud?(user, entity_name)
      admin?(user) || GogglesDb::AdminGrant.exists?(user_id: user.id, entity: entity_name)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the User specified in the constructor can do anything.
    # False otherwise.
    def admin?
      @grants.find { |grant| grant.entity.nil? }.present?
    end

    # Returns +true+ if the User specified in the constructor can do anything
    # on the specified entity.
    def crud?(entity_name)
      admin? || @grants.find { |grant| grant.entity == entity_name }.present?
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
