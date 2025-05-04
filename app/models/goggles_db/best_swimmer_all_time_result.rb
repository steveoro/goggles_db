# frozen_string_literal: true

module GogglesDb
  # = BestSwimmerAllTimeResult (Scenic View model)
  #
  # Collects the overall best results for each swimmer.
  #
  class BestSwimmerAllTimeResult < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_swimmer_all_time_results'
  end
end
