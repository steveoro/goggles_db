# frozen_string_literal: true

module GogglesDb
  #
  # = "Manager checker" wrapper/strategy object
  #
  #   - file vers.: 7.4.25
  #   - author....: Steve A.
  #   - build.....: 20230131
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

    # Similarly to Returns <tt>self.for_affiliation?()</tt>, returns +true+ if the specified User
    # manages any team affiliation for the specified season.
    #
    # == Params:
    # - user: the GogglesDb::User instance to be checked for managing grants;
    # - season: the GogglesDb::Season instance in which the user may manage any team.
    #
    def self.any_for?(user, season)
      return false unless user.instance_of?(User) && season.instance_of?(Season)

      GrantChecker.admin?(user) ||
        GrantChecker.crud?(user, 'Team') ||
        GrantChecker.crud?(user, 'TeamAffiliation') ||
        GogglesDb::ManagedAffiliation.includes(:team_affiliation).joins(:team_affiliation)
                                     .exists?(
                                       user_id: user.id,
                                       'team_affiliations.season_id': season.season_id
                                     )
    end
  end
end
