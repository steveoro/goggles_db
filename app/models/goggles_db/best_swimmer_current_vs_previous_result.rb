# frozen_string_literal: true

module GogglesDb
  # = BestSwimmerCurrentVsPreviousResult (Scenic View model)
  #
  # Collects the best result for each swimmer/event/pool in the reference championship
  # year, with optional old timing columns from the previous 3-year window.
  # The reference year defaults to the latest ongoing championship year and can be
  # overridden via AbstractBestResult.with_base_year(year).
  #
  class BestSwimmerCurrentVsPreviousResult < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_swimmer_current_vs_previous_results'
  end
end
