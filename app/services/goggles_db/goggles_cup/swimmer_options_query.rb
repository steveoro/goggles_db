# frozen_string_literal: true

module GogglesDb
  module GogglesCup
    # = GogglesDb::GogglesCup::SwimmerOptionsQuery
    #
    # Lists swimmers for the GogglesCup primary-team domain.
    #
    # The list merges two sources:
    # - swimmers having a valid result for the team in the reference championship
    #   year (from the best_swimmer_current_vs_previous_results Scenic view, which
    #   honors the +@base_year+ session variable set by the caller);
    # - swimmers holding a Badge for the same team in the current OR in the
    #   previous MASFIN championship year, so that the list is populated also at
    #   the start of a new season, when no badges or results exist yet.
    #
    # (Ported from goggles_admin2's GogglesCup::SwimmerOptionsQuery.)
    class SwimmerOptionsQuery
      # == Params:
      # - team_id:   the primary Team id (required)
      # - base_year: the reference championship year for the badge lookup;
      #              defaults to the current championship year
      def initialize(team_id:, base_year: nil)
        @team_id = team_id
        @base_year = base_year.presence&.to_i || GogglesDb::Season.current_championship_year(GogglesDb::SeasonType.mas_fin)
      end

      def call
        rows.map do |row|
          {
            swimmer_id: row[0],
            swimmer_name: row[1],
            swimmer_year_of_birth: row[2]
          }
        end
      end

      def smart_selected_ids_for(secondary_team_id)
        return [] if secondary_team_id.blank?

        GogglesDb::Badge
          .where(team_id: secondary_team_id, swimmer_id: rows.map(&:first))
          .distinct
          .pluck(:swimmer_id)
      end

      private

      def rows
        @rows ||= (result_rows + badge_rows).uniq(&:first).sort_by { |row| row[1].to_s }
      end

      def result_rows
        GogglesDb::BestSwimmerCurrentVsPreviousResult
          .where(team_id: @team_id)
          .distinct
          .pluck(:swimmer_id, :swimmer_name, :swimmer_year_of_birth)
      end

      def badge_rows
        GogglesDb::Badge
          .joins(:season, :swimmer)
          .where(team_id: @team_id)
          .merge(
            GogglesDb::Season
              .for_season_type(GogglesDb::SeasonType.mas_fin)
              .for_championship_year(@base_year, @base_year - 1)
          )
          .distinct
          .pluck('swimmers.id', 'swimmers.complete_name', 'swimmers.year_of_birth')
      end
    end
  end
end
