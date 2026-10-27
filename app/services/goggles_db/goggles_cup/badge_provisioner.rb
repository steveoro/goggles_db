# frozen_string_literal: true

module GogglesDb
  module GogglesCup
    # = GogglesDb::GogglesCup::BadgeProvisioner
    #
    # Creates, for each swimmer enlisted in a GoggleCup and missing one, the
    # Badge binding the swimmer to the cup's team for the latest MASFIN season
    # (the common "parent" championship that also includes LEN/FINA results).
    # The TeamAffiliation for (team, season) is auto-created as well when
    # missing, flagged with +autofilled+.
    #
    # Rationale: a cup selection may include swimmers that have no results and
    # no badge yet for the managed team; without the badge, the
    # swimmer↔team affiliation cannot be resolved for the current season
    # (e.g. for the swimmer's own dashboard cup button or for the
    # SmartSelection defaults).
    #
    # Missing badges are the only rows created: badges already existing for
    # (swimmer, team, season) are reported, never modified.
    class BadgeProvisioner
      # == Params:
      # - cup: the GogglesDb::GoggleCup being saved (required)
      def initialize(cup)
        @cup = cup
      end

      # Returns a report hash:
      # { created: [Badge], existing: [Badge], skipped: [{ swimmer_id:, reason: }] }
      # Possible skip reasons: :swimmer_not_found, :no_season, :no_category_type.
      def call
        report = { created: [], existing: [], skipped: [] }
        return report if @cup.swimmer_ids_array.blank?
        return report.merge(skipped: @cup.swimmer_ids_array.map { |id| { swimmer_id: id, reason: :no_season } }) if season.nil?

        @cup.swimmer_ids_array.each do |swimmer_id|
          provision_for(swimmer_id, report)
        end
        report
      end

      private

      # The latest MASFIN season for the current championship year.
      def season
        @season ||= begin
          year = GogglesDb::Season.current_championship_year(GogglesDb::SeasonType.mas_fin)
          GogglesDb::Season.for_season_type(GogglesDb::SeasonType.mas_fin)
                           .for_championship_year(year)
                           .first
        end
      end

      def team_affiliation
        @team_affiliation ||= GogglesDb::TeamAffiliation.find_or_create_by(
          team_id: @cup.team_id, season_id: season.id
        ) do |affiliation|
          affiliation.name = @cup.team.name
          affiliation.autofilled = true
        end
      end

      # Enlisted swimmers, memoized to avoid N+1 lookups.
      def swimmers_by_id
        @swimmers_by_id ||= GogglesDb::Swimmer.where(id: @cup.swimmer_ids_array).index_by(&:id)
      end

      # Badges already existing for (swimmer, cup team, latest MASFIN season).
      def existing_badges_by_swimmer_id
        @existing_badges_by_swimmer_id ||= GogglesDb::Badge.where(
          swimmer_id: @cup.swimmer_ids_array, team_id: @cup.team_id, season_id: season.id
        ).index_by(&:swimmer_id)
      end

      def provision_for(swimmer_id, report)
        swimmer = swimmers_by_id[swimmer_id]
        return report[:skipped] << { swimmer_id: swimmer_id, reason: :swimmer_not_found } if swimmer.nil?

        return report[:existing] << existing_badges_by_swimmer_id[swimmer_id] if existing_badges_by_swimmer_id[swimmer_id]

        category_type = swimmer.latest_category_type(GogglesDb::SeasonType.mas_fin)
        return report[:skipped] << { swimmer_id: swimmer_id, reason: :no_category_type } if category_type.nil?

        report[:created] << GogglesDb::Badge.create!(
          swimmer_id: swimmer_id,
          team_id: @cup.team_id,
          season_id: season.id,
          team_affiliation_id: team_affiliation.id,
          category_type_id: category_type.id,
          entry_time_type_id: GogglesDb::EntryTimeType::GOGGLECUP_ID,
          number: '?'
        )
      end
    end
  end
end
