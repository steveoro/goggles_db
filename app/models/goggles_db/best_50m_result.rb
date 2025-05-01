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
  class Best50mResult < ApplicationRecord
    # Tell Rails this model is backed by a view, not a table
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'best_50m_results'

    # Define associations for easier data access (optional but helpful)
    belongs_to :swimmer
    belongs_to :event_type
    belongs_to :pool_type
    belongs_to :season
    belongs_to :gender_type
    belongs_to :meeting
    belongs_to :meeting_individual_result # Link back to the original result record
    belongs_to :team # Team associated with the result itself

    # --- Read-only View ---
    # Prevent accidental attempts to write to the view
    def readonly?
      true
    end

    # --- Helper Methods ---

    # Returns the timing formatted as a string (e.g., "0'58\"45")
    # using the Timing wrapper class.
    def timing
      Timing.new(minutes: minutes, seconds: seconds, hundredths: hundredths).to_s
    end

    # Simple scope to filter results by swimmers belonging to a specific team in a specific season
    # This is the primary way this view will be used.
    #
    # Usage:
    #   GogglesDb::Best50mResult.for_team_id(team_id)
    #
    scope :for_team_id, ->(team_id) { where(team_id: team_id).distinct }

    # Simple scope to filter results by swimmers belonging to a specific team in a specific season
    # This is the primary way this view will be used.
    #
    # Usage:
    #   GogglesDb::Best50mResult.for_team_and_season_ids(team_id, season_id)
    #
    scope :for_team_and_season_ids, ->(team_id, season_id) { where(team_id: team_id, season_id: season_id).distinct }
  end
end
