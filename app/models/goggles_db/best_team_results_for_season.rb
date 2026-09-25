# frozen_string_literal: true

module GogglesDb
  # = BestTeamResultsForSeason (Scenic View model)
  #
  # Collects the best individual results ("team records") for each team & season:
  # one row per supported "meeting program" tuple
  # (event_type x category_type x gender_type x pool_type) holding the single best,
  # non-zero, non-disqualified timing achieved by *any* swimmer badged to that team
  # in that season.
  #
  # Filter by team & season with the usual scopes, e.g.:
  #   BestTeamResultsForSeason.for_team_and_season_ids(team_id, season_id)
  #
  # Tuples with no valid result simply yield no row: a consumer building the full
  # record matrix can enumerate the tuple space (events x the season's
  # category_types x genders x pools) and left-join these rows on it.
  #
  # For "all time" (season-less) team records, chain `all_time_best`: it keeps,
  # per program tuple, only the single row holding the best (lowest) timing
  # across every season the team has results in, e.g.:
  #   BestTeamResultsForSeason.for_team_id(team_id).all_time_best
  #
  class BestTeamResultsForSeason < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_team_results_for_season'

    # Individual event types supported by the view (mirrors the SQL filter).
    SUPPORTED_EVENT_TYPE_IDS = [2, 3, 4, 5, 6, 7, 11, 12, 13, 15, 16, 17, 19, 20, 21, 22, 23, 24].freeze

    belongs_to :category_type

    # Scope to filter results by category type.
    scope :for_category_type, lambda { |category_type|
      category_id = category_type.is_a?(CategoryType) ? category_type.id : category_type
      where(category_type_id: category_id)
    }

    # Scope keeping, for each team + program tuple, only the single row holding
    # the best timing across all seasons (ignoring the view's per-season split).
    # Rows still rank by the view's ordering (timing, then most recent meeting),
    # so equal timings resolve deterministically to the latest result.
    scope :all_time_best, lambda {
      ranked_ids = sanitize_sql_array([<<~SQL.squish, table_name])
        SELECT meeting_individual_result_id FROM (
          SELECT meeting_individual_result_id,
                 ROW_NUMBER() OVER (
                   PARTITION BY team_id, event_type_id, category_type_id, gender_type_id, pool_type_id
                   ORDER BY total_hundredths ASC, meeting_date DESC, meeting_id DESC
                 ) AS rn
          FROM %s
        ) ranked_records
        WHERE rn = 1
      SQL
      where("meeting_individual_result_id IN (#{ranked_ids})")
    }

    # Scope returning the team records: the single best (lowest, positive,
    # non-disqualified) MIR per program tuple — event type x category type CODE
    # x gender type x pool type — for a given team, optionally restricted to a
    # subset of seasons (e.g. all season ids sharing a championship year).
    #
    # Tuples are deduplicated by category code (not id), since the same code
    # maps to different category_type ids across season-type editions.
    #
    # Unlike `for_team_id(...).all_time_best`, this query reads
    # meeting_individual_results filtered by team *before* ranking, instead of
    # materializing the whole view: its cost scales with the team's results,
    # not with the database size — use it for per-team record pages.
    #
    # Returns a relation mapped on this model (same columns as the view), so
    # associations and `includes` keep working.
    scope :team_records, lambda { |team_id, season_ids = nil|
      season_filter = season_ids.present? ? 'AND m.season_id IN (:season_ids)' : nil
      ranked_sql = sanitize_sql_array([
                                        format(<<~SQL.squish, season_filter: season_filter.to_s),
                                          SELECT * FROM (
                                            SELECT
                                              mir.swimmer_id,
                                              s.complete_name AS swimmer_name,
                                              s.year_of_birth AS swimmer_year_of_birth,
                                              mp.gender_type_id,
                                              gt.code AS gender_type_code,
                                              me.event_type_id,
                                              et.code AS event_type_code,
                                              mp.category_type_id,
                                              ct.code AS category_type_code,
                                              ct.short_name AS category_type_short_name,
                                              mp.pool_type_id,
                                              pt.code AS pool_type_code,
                                              m.season_id,
                                              se.header_year AS season_header_year,
                                              st.federation_type_id,
                                              mir.id AS meeting_individual_result_id,
                                              mir.minutes,
                                              mir.seconds,
                                              mir.hundredths,
                                              (mir.minutes * 6000 + mir.seconds * 100 + mir.hundredths) AS total_hundredths,
                                              m.id AS meeting_id,
                                              m.header_date AS meeting_date,
                                              m.description AS meeting_name,
                                              b.team_id,
                                              t.name AS team_name,
                                              ROW_NUMBER() OVER (
                                                PARTITION BY me.event_type_id, ct.code, mp.gender_type_id, mp.pool_type_id
                                                ORDER BY
                                                  (mir.minutes * 6000 + mir.seconds * 100 + mir.hundredths) ASC,
                                                  m.header_date DESC,
                                                  m.id DESC
                                              ) AS rn
                                            FROM meeting_individual_results mir
                                            JOIN badges b ON b.id = mir.badge_id
                                            JOIN meeting_programs mp ON mp.id = mir.meeting_program_id
                                            JOIN meeting_events me ON me.id = mp.meeting_event_id
                                            JOIN meeting_sessions ms ON ms.id = me.meeting_session_id
                                            JOIN meetings m ON m.id = ms.meeting_id
                                            JOIN seasons se ON se.id = m.season_id
                                            JOIN season_types st ON st.id = se.season_type_id
                                            JOIN event_types et ON et.id = me.event_type_id
                                            JOIN category_types ct ON ct.id = mp.category_type_id
                                            JOIN gender_types gt ON gt.id = mp.gender_type_id
                                            JOIN pool_types pt ON pt.id = mp.pool_type_id
                                            JOIN swimmers s ON s.id = mir.swimmer_id
                                            JOIN teams t ON t.id = b.team_id
                                            WHERE
                                              mir.disqualified = false
                                              AND (mir.minutes * 6000 + mir.seconds * 100 + mir.hundredths) > 0
                                              AND me.event_type_id IN (2, 3, 4, 5, 6, 7, 11, 12, 13, 15, 16, 17, 19, 20, 21, 22, 23, 24)
                                              AND mp.pool_type_id IN (1, 2)
                                              AND mp.gender_type_id IN (1, 2)
                                              AND b.season_id = m.season_id
                                              AND b.team_id = :team_id
                                              %<season_filter>s
                                          ) ranked_records
                                          WHERE rn = 1
                                        SQL
                                        { team_id: team_id, season_ids: Array(season_ids) }
                                      ])
      unscoped.from(Arel.sql("(#{ranked_sql}) #{table_name}"))
    }
  end
end
