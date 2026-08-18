# frozen_string_literal: true

module GogglesDb
  # = MeetingIndividualResultRow (Scenic View model)
  #
  # Flattened, read-only row for each MeetingIndividualResult, including all
  # displayable scalars (event/program/category/gender ordering keys, swimmer &
  # team names, scores, timing) plus the associated laps aggregated as JSON.
  #
  # Enables rendering all individual results of a meeting with a single query:
  #
  #   GogglesDb::MeetingIndividualResultRow.for_meeting(meeting_id).by_meeting_order
  #
  # The source MIR row remains editable through the usual models: this view
  # always reflects live data (it's not materialized).
  #
  class MeetingIndividualResultRow < AbstractResultRow
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'meeting_individual_result_rows'

    belongs_to :meeting_individual_result
    belongs_to :swimmer
    belongs_to :badge, optional: true

    # Returns the list of associated laps as an Array of JsonRow instances
    # (already sorted by length_in_meters), decoded from the aggregated JSON column.
    def laps
      @laps ||= JSON.parse(laps_json || '[]').map { |hash| JsonRow.new(hash) }
    end
  end
end
