# frozen_string_literal: true

module GogglesDb
  # = BestSwimmerCurrentVsPreviousResult (Scenic View model)
  #
  # Collects the best result for each swimmer/event/pool in the latest ongoing season,
  # with optional old timing columns from the previous season.
  #
  class BestSwimmerCurrentVsPreviousResult < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_swimmer_current_vs_previous_results'
  end
end
