# frozen_string_literal: true

module GogglesDb
  module GogglesCup
    # = GogglesDb::GogglesCup::ManagedTeamResolver
    #
    # Resolves the primary-team context of the GogglesCup page for the current user.
    #
    # - admins can freely choose any team (#can_choose_any_team? => true and
    #   #managed_teams is left empty, meaning "unrestricted");
    # - managers get the list of teams they can manage;
    # - #default_team is the team to preselect for the shown championship year:
    #   1. the team of the first ManagedAffiliation of the user for the seasons
    #      belonging to that championship year;
    #   2. the team of the Badge for the same seasons of the Swimmer associated
    #      to the user (if any);
    #   3. +nil+ (free choice).
    #
    # (Ported from goggles_admin2's GogglesCup::ManagedTeamResolver, with the
    # added +restrict_to_shown_season+ option used by goggles_main to scope the
    # manageable teams to the seasons belonging to the shown championship year.)
    class ManagedTeamResolver
      # == Params:
      # - user:                     the current GogglesDb::User (required)
      # - season_year:              the championship year currently shown
      #                             (defaults to the current championship year)
      # - restrict_to_shown_season: when true, #managed_team_ids only reports
      #                             affiliations bound to a season of the shown
      #                             championship year; when false (default), any
      #                             managed affiliation counts (admin2 behavior)
      def initialize(user:, season_year: nil, restrict_to_shown_season: false)
        @user = user
        @season_year = season_year.presence&.to_i || GogglesDb::Season.current_championship_year(GogglesDb::SeasonType.mas_fin)
        @restrict_to_shown_season = restrict_to_shown_season
      end

      # Returns true when the user can pick any team (admin grants).
      def can_choose_any_team?
        @can_choose_any_team ||= GogglesDb::GrantChecker.admin?(@user)
      end

      # Returns the list of manageable teams for the user.
      # Left empty for admins (meaning: unrestricted choice).
      def managed_teams
        @managed_teams ||= can_choose_any_team? ? GogglesDb::Team.none : GogglesDb::Team.where(id: managed_team_ids)
      end

      # Returns the distinct team ids the user manages.
      def managed_team_ids
        @managed_team_ids ||= manageable_affiliations.distinct.pluck('team_affiliations.team_id')
      end

      # Returns the default primary Team for the shown championship year, or +nil+.
      def default_team
        @default_team ||= managed_affiliation_team || badge_team
      end

      private

      def manageable_affiliations
        scope = GogglesDb::ManagedAffiliation
                .where(user_id: @user.id)
                .joins(team_affiliation: :season)
        @restrict_to_shown_season ? scope.merge(shown_seasons) : scope
      end

      def shown_seasons
        @shown_seasons ||= GogglesDb::Season.for_championship_year(@season_year)
      end

      def managed_affiliation_team
        manageable_affiliations
          .merge(shown_seasons)
          .order('managed_affiliations.id')
          .first&.team_affiliation&.team
      end

      def badge_team
        return nil if @user&.swimmer_id.blank?

        GogglesDb::Badge
          .joins(:season)
          .merge(shown_seasons)
          .where(swimmer_id: @user.swimmer_id)
          .first&.team
      end
    end
  end
end
