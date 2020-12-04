# frozen_string_literal: true

module GogglesDb
  #
  # = "Grant checker" wrapper/strategy object
  #
  #   - file vers.: 1.01
  #   - author....: Steve A.
  #   - build.....: 20201204
  #
  #   Checks if a specified User instance has either specific admin-grants for a certain
  #   entity or has generic administrative rights.
  #
  class GrantChecker
    # Returns +true+ if the specified User can do anything.
    #
    def self.admin?(user)
      GogglesDb::AdminGrant.exists?(user_id: user.id, entity: nil)
    end

    # Returns +true+ if the specified User can do anything on the specified entity.
    #
    def self.crud?(user, entity_name)
      admin?(user) || GogglesDb::AdminGrant.exists?(user_id: user.id, entity: entity_name)
    end
  end
end
