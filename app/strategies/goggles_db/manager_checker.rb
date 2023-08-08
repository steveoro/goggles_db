# frozen_string_literal: true

module GogglesDb
  #
  # = "Manager checker" wrapper/strategy object
  #
  #   - file vers.: 7.05.01
  #   - author....: Steve A.
  #   - build.....: 20230328
  #
  #  Checks if the specified User instance can manage or handle the
  #  specific instances supplied as parameters.
  #
  class ManagerChecker
    # Constructor. Prepares a reusable instance by setting a default User and a target Season ID.
    #
    # === Params
    # - user: subject User instance.
    # - season_id: target Season ID.
    #
    def initialize(user, season_id)
      raise ArgumentError, 'Invalid GogglesDb::User or Season ID specified.' unless user.is_a?(GogglesDb::User) && GogglesDb::Season.exists?(season_id)

      @user = user
      @season_id = season_id
      @admin_grants = GrantChecker.admin?(user)
      @team_crud_grants = GrantChecker.crud?(user, 'Team') || GrantChecker.crud?(user, 'TeamAffiliation')
      @swimmer_crud_grants = GrantChecker.crud?(user, 'Swimmer') || GrantChecker.crud?(user, 'Badge')
      @managed_teams_ids = user.managed_affiliations.includes(team_affiliation: %i[team season])
                               .joins(team_affiliation: %i[team season])
                               .where(user_id: user.id,
                                      'team_affiliations.season_id': season_id)
                               .map { |ma| ma.team_affiliation.team_id }
                               .uniq
      @managed_swimmer_ids = GogglesDb::Badge.where(season_id:, team_id: @managed_teams_ids)
                                             .pluck(:swimmer_id)
                                             .uniq
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the specified User can manage the specified team affiliation.
    #
    # == Params:
    # - user: the GogglesDb::User instance to be checked for managing grants;
    # - team_affiliation_id: the ID of the GogglesDb::TeamAffiliation that the user is supposed to manage.
    #
    def self.for_affiliation?(user, team_affiliation_id)
      return false unless user.instance_of?(User) && GogglesDb::TeamAffiliation.exists?(team_affiliation_id)

      GrantChecker.admin?(user) ||
        GrantChecker.crud?(user, 'Team') ||
        GrantChecker.crud?(user, 'TeamAffiliation') ||
        GogglesDb::ManagedAffiliation.exists?(user_id: user.id, team_affiliation_id:)
    end

    # Similarly to <tt>self.for_affiliation?()</tt>, returns +true+ if the specified User
    # manages any team affiliation for the specified season.
    #
    # == Params:
    # - user: the GogglesDb::User instance to be checked for managing grants;
    # - season_id: the ID of the GogglesDb::Season in which the user may manage any team.
    #
    def self.any_for?(user, season_id)
      return false unless user.instance_of?(User) && GogglesDb::Season.exists?(season_id)

      GrantChecker.admin?(user) ||
        GrantChecker.crud?(user, 'Team') ||
        GrantChecker.crud?(user, 'TeamAffiliation') ||
        GogglesDb::ManagedAffiliation.includes(:team_affiliation).joins(:team_affiliation)
                                     .exists?(user_id: user.id, 'team_affiliations.season_id': season_id)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Checks grants & team affiliations, returning either +true+ or +false+, depending whether the
    # specified +team_id+ can be managed by the current #user set with the constructor of this instance.
    def for_team?(team_id)
      return true if @admin_grants || @team_crud_grants

      @managed_teams_ids.include?(team_id)
    end

    # Checks grants & swimmer association, returning either +true+ or +false+, depending whether the
    # specified +swimmer_id+ can be managed by the current #use set with the constructor of this instance.
    def for_swimmer?(swimmer_id)
      return true if @admin_grants || @swimmer_crud_grants

      (@user.swimmer_id == swimmer_id) || @managed_swimmer_ids.include?(swimmer_id)
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
