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
  class BestTeamResultsForSeason < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_team_results_for_season'

    belongs_to :category_type

    # Scope to filter results by category type.
    scope :for_category_type, lambda { |category_type|
      category_id = category_type.is_a?(CategoryType) ? category_type.id : category_type
      where(category_type_id: category_id)
    }
  end
end
