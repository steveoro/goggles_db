# frozen_string_literal: true

module GogglesDb
  # = BestSwimmer5yResult (Scenic View model)
  #
  # Collects all best results for each swimmer during the span of the last 5 years
  #
  class BestSwimmer5yResult < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_swimmer5y_results'
  end
end
