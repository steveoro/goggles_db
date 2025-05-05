# frozen_string_literal: true

module GogglesDb
  # = BestSwimmer3yResult (Scenic View model)
  #
  # Collects all best results for each swimmer during the span of the last 3 years
  #
  class BestSwimmer3yResult < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_swimmer3y_results'
  end
end
