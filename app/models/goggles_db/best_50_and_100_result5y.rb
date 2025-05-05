# frozen_string_literal: true

module GogglesDb
  # == Best50And100Result5y
  #
  # Model class containing the results for the best performances over 50m and 100m distances,
  # using an expanded range of event types (every stroke type for 50m and 100m as maximum length).
  #
  # Does not take into account the seasons but just a limited span of 5 years.
  #
  class Best50And100Result5y < AbstractBestResult
    # Define the primary key for the view
    self.primary_key = :meeting_individual_result_id

    # Explicitly set table name because engine prefixing convention isn't working as expected
    self.table_name = 'best_50_and_100_results5y'
  end
end
