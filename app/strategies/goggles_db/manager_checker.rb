# frozen_string_literal: true

module GogglesDb
  #
  # = "Manager checker" wrapper/strategy object
  #
  #   - file vers.: 7.03
  #   - author....: Steve A.
  #   - build.....: 20210614
  #
  #  Checks if the specified User instance can manage or handle the
  #  specific instances supplied as parameters.
  #
  class ManagerChecker
    # Returns +true+ if the specified User can manage the specified team affiliation.
    #
    # == Params:
    # - user: the GogglesDb::User instance to be checked for managing grants;
    # - team_affiliation: the GogglesDb::TeamAffiliation instance that the user allegedly can manage.
    #
    def self.for_affiliation?(user, team_affiliation)
      return false unless user.instance_of?(User) && team_affiliation.instance_of?(TeamAffiliation)

      GrantChecker.admin?(user) ||
        GrantChecker.crud?(user, 'Team') ||
        GrantChecker.crud?(user, 'TeamAffiliation') ||
        GogglesDb::ManagedAffiliation.exists?(user_id: user.id, team_affiliation_id: team_affiliation.id)
    end
  end
end
