# frozen_string_literal: true

module GogglesDb
  # == AbstractBestResult
  #
  # Abstract base class for all models backed by a view reporting the
  # "best" results, typically based on MeetingIndividualResult data.
  #
  # This class provides common functionality and scopes for these models.
  # It is not meant to be instantiated directly.
  #
  class AbstractBestResult < ApplicationRecord
    include TimingManageable

    self.abstract_class = true

    # Disable STI for this model, as it's an abstract base and children
    # represent different views, not types within the same table.
    self.inheritance_column = :_type_disabled

    # --- Read-only View ---
    # Prevent accidental attempts to write to the view
    def readonly?
      true
    end

    # --- Associations ---
    # Define common associations for easier data access
    belongs_to :swimmer
    belongs_to :event_type
    belongs_to :gender_type
    belongs_to :pool_type
    belongs_to :season
    belongs_to :meeting
    belongs_to :meeting_individual_result # Link back to the original result record
    belongs_to :team # Team associated with the result itself

    # --- Common Scopes ---

    default_scope do
      includes(
        :swimmer, :team, :event_type, :gender_type, :pool_type,
        :season, :meeting, :meeting_individual_result
      )
    end

    # Scope to filter results by swimmer gender.
    scope :for_gender, lambda { |gender_type|
      gender_id = gender_type.is_a?(GenderType) ? gender_type.id : gender_type
      where(gender_type_id: gender_id)
    }

    # Scope to filter results by event type.
    scope :for_event_type, lambda { |event_type|
      event_id = event_type.is_a?(EventType) ? event_type.id : event_type
      where(event_type_id: event_id)
    }

    # Scope to filter results by pool type.
    scope :for_pool_type, lambda { |pool_type|
      pool_id = pool_type.is_a?(PoolType) ? pool_type.id : pool_type
      where(pool_type_id: pool_id)
    }

    # Scope to filter results by season.
    scope :for_season, lambda { |season|
      season_id = season.is_a?(Season) ? season.id : season
      where(season_id: season_id)
    }

    # Scope to filter results by the team associated with the result.
    scope :for_team_id, ->(team_id) { where(team_id: team_id).distinct }

    # Scope to filter results by the team and season associated with the result.
    scope :for_team_and_season_ids, ->(team_id, season_id) { where(team_id: team_id, season_id: season_id).distinct }

    # Scope to sort results by time (fastest first).
    # Assumes the presence of a 'total_hundredths' column or similar calculable timing field.
    scope :sort_by_time, -> { order(:total_hundredths) }

    # Alias for sort_by_time for clarity
    scope :sort_fastest_first, -> { sort_by_time }

    # Scope to sort results by time (slowest first).
    scope :sort_by_time_desc, -> { order(total_hundredths: :desc) }
  end
end
