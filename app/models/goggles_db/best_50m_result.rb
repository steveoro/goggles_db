# frozen_string_literal: true

module GogglesDb
  # = Best50mResult (Scenic View model)
  #
  # Represents the database view 'best_50m_results'.
  # This view contains the single fastest, non-disqualified 50-meter result
  # (Freestyle, Backstroke, Breaststroke, Butterfly) for each swimmer
  # in each pool type (25m, 50m) achieved during the 3 most recent 'FIN' seasons (for version 3).
  #
  # The view provides pre-calculated best times, simplifying queries for team managers
  # who need to find the top performances for swimmers currently affiliated with their team.
  #
  # Also, as a reminder, ONLY the 3 MOST RECENT 'FIN' seasons are selected, so most of the times
  # there no need for an additional season filter (although available, in case only the results
  # from a specific season are needed).
  #
  # == Attributes
  #
  # - swimmer_id
  # - swimmer_name
  # - swimmer_year_of_birth
  # - gender_type_id
  # - event_type_id
  # - event_type_code (e.g., '50SL', '50FA')
  # - pool_type_id (1=25m, 2=50m)
  # - pool_type_code (e.g., '25', '50')
  # - season_id (Season where the best result occurred)
  # - season_header_year (e.g., '2023/2024')
  # - meeting_individual_result_id (ID of the source MIR record)
  # - minutes
  # - seconds
  # - hundredths
  # - total_hundredths (calculated: minutes*6000 + seconds*100 + hundredths)
  # - meeting_id
  # - meeting_date
  # - meeting_name
  # - team_id (Team under which the best result was achieved)
  # - team_name
  #
  class Best50mResult < AbstractBestResult
    # Tell Rails this model is backed by a view, not a table
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_50m_results'
  end
end
