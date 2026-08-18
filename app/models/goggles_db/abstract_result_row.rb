# frozen_string_literal: true

module GogglesDb
  # == AbstractResultRow
  #
  # Abstract base class for the flattened, read-only "result row" views
  # (meeting_individual_result_rows & meeting_relay_result_rows).
  #
  # Each concrete sibling maps one row per source result (MIR or MRR) and
  # carries all displayable scalars plus the associated laps/legs aggregated
  # as JSON, so that a whole meeting results page can be rendered with a
  # single query (filtered by meeting_id).
  #
  # These views are *not* materialized: they always reflect live data from the
  # base tables, so any edit made through the normal models (e.g. lap editing
  # by team managers) is immediately visible on the next read.
  #
  class AbstractResultRow < ApplicationRecord
    include TimingManageable

    self.abstract_class = true

    # Disable STI: children map different views, not types within a table.
    self.inheritance_column = :_type_disabled

    # --- Read-only view: prevent accidental writes ---
    def readonly?
      true
    end

    # --- Common associations (no default eager-loading on purpose) ---
    belongs_to :meeting
    belongs_to :meeting_session
    belongs_to :meeting_event
    belongs_to :meeting_program
    belongs_to :team
    belongs_to :season
    belongs_to :season_type
    belongs_to :event_type
    belongs_to :category_type
    belongs_to :gender_type
    belongs_to :pool_type

    # --- Common scopes ---

    # Filters rows by meeting.
    scope :for_meeting, lambda { |meeting|
      meeting_id = meeting.is_a?(Meeting) ? meeting.id : meeting
      where(meeting_id:)
    }

    # Filters rows by team.
    scope :for_team, lambda { |team|
      team_id = team.is_a?(Team) ? team.id : team
      where(team_id:)
    }

    # Filters rows by meeting event.
    scope :for_meeting_event, lambda { |meeting_event|
      meeting_event_id = meeting_event.is_a?(MeetingEvent) ? meeting_event.id : meeting_event
      where(meeting_event_id:)
    }

    # Default rendering order for a whole meeting page:
    # session & event order first, then category age, gender and timing.
    scope :by_meeting_order, lambda {
      order(:session_order, :event_order, :category_age_begin,
            gender_type_id: :desc, total_hundredths: :asc)
    }

    # Sorting scopes compatible with AbstractResult (for table components):
    scope :by_rank, ->(dir = :asc) { order(disqualified: :asc, rank: dir.to_s.downcase.to_sym) }
    scope :by_timing, lambda { |dir = :asc|
      order(disqualified: :asc, total_hundredths: dir.to_s.downcase.to_sym)
    }

    # Rows to be included in rankings (positive rank & timing).
    scope :with_rank, -> { where('`rank` > 0 AND total_hundredths > 0') }

    # Rows to be excluded from rankings (missing rank or timing).
    scope :with_no_rank, -> { where('`rank` = 0 OR total_hundredths = 0') }

    # Compatibility alias for components that rely on AbstractResult#parent_meeting.
    def parent_meeting
      meeting
    end
  end
end
