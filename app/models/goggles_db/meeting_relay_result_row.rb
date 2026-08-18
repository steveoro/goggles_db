# frozen_string_literal: true

module GogglesDb
  # = MeetingRelayResultRow (Scenic View model)
  #
  # Flattened, read-only row for each MeetingRelayResult, including all
  # displayable scalars (event/program/category/gender ordering keys, team
  # names, scores, timing) plus the associated relay swimmers ("legs") and
  # relay laps aggregated as JSON.
  #
  # Enables rendering all relay results of a meeting with a single query:
  #
  #   GogglesDb::MeetingRelayResultRow.for_meeting(meeting_id).by_meeting_order
  #
  # The source MRR row remains editable through the usual models: this view
  # always reflects live data (it's not materialized).
  #
  class MeetingRelayResultRow < AbstractResultRow
    self.primary_key = :meeting_relay_result_id
    self.table_name = 'meeting_relay_result_rows'

    belongs_to :meeting_relay_result

    # Returns the list of associated relay swimmers ("legs") as an Array of
    # JsonRow instances sorted by relay_order, decoded from the aggregated
    # JSON column. Each leg responds also to #relay_laps, returning its own
    # sub-laps (Array of JsonRow, sorted by length_in_meters).
    def relay_swimmers
      @relay_swimmers ||= begin
        laps_by_leg = relay_laps.group_by(&:meeting_relay_swimmer_id)
        JSON.parse(relay_swimmers_json || '[]').map do |hash|
          leg = JsonRow.new(hash)
          leg_laps = laps_by_leg.fetch(leg.id, [])
          leg.define_singleton_method(:relay_laps) { leg_laps }
          leg
        end
      end
    end

    # Returns the flat list of all associated relay laps as an Array of JsonRow
    # instances (sorted by length_in_meters), decoded from the aggregated JSON
    # column. Each item carries its parent #meeting_relay_swimmer_id.
    def relay_laps
      @relay_laps ||= JSON.parse(relay_laps_json || '[]').map { |hash| JsonRow.new(hash) }
    end
  end
end
