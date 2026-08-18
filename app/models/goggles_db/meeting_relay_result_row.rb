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
  class MeetingRelayResultRow < AbstractResultRow
    self.primary_key = :meeting_relay_result_id
    self.table_name = 'meeting_relay_result_rows'

    belongs_to :meeting_relay_result

    # Returns the list of associated relay swimmers ("legs") as an Array of
    # JsonRow instances sorted by relay_order, decoded from the aggregated
    # JSON column. Each leg responds also to #relay_laps, #stroke_type, #swimmer
    # and #meeting, so it can be used by the same relay-lap table components
    # that normally consume MeetingRelaySwimmer ActiveRecord instances.
    def relay_swimmers
      @relay_swimmers ||= build_relay_swimmers
    end

    # Returns the flat list of all associated relay laps as an Array of JsonRow
    # instances (sorted by length_in_meters), decoded from the aggregated JSON
    # column. Each item carries its parent #meeting_relay_swimmer_id.
    def relay_laps
      @relay_laps ||= JSON.parse(relay_laps_json || '[]').map { |hash| JsonRow.new(hash) }
    end

    private

    # Builds the JsonRow legs by preloading the lookup tables once.
    def build_relay_swimmers
      parsed = JSON.parse(relay_swimmers_json || '[]')
      swimmers = preload_swimmers_for(parsed)
      strokes = preload_strokes_for(parsed)
      laps_by_leg = relay_laps.group_by(&:meeting_relay_swimmer_id)
      parent_meeting = meeting

      parsed.map do |hash|
        build_relay_swimmer(hash, laps_by_leg, swimmers, strokes, parent_meeting)
      end
    end

    # Preloads Swimmer rows needed by the parsed JSON array.
    def preload_swimmers_for(parsed)
      ids = parsed.pluck('swimmer_id').compact.uniq
      GogglesDb::Swimmer.where(id: ids).index_by(&:id)
    end

    # Preloads StrokeType rows needed by the parsed JSON array.
    def preload_strokes_for(parsed)
      ids = parsed.pluck('stroke_type_id').compact.uniq
      GogglesDb::StrokeType.where(id: ids).index_by(&:id)
    end

    # Returns a JsonRow for a single relay swimmer, enriched with helper methods.
    def build_relay_swimmer(hash, laps_by_leg, swimmers, strokes, parent_meeting)
      leg = JsonRow.new(hash)
      leg_laps = laps_by_leg.fetch(leg.id, [])
      leg.define_singleton_method(:relay_laps) { leg_laps }
      leg.define_singleton_method(:stroke_type) { strokes[leg.stroke_type_id] }
      leg.define_singleton_method(:swimmer) { swimmers[leg.swimmer_id] }
      leg.define_singleton_method(:meeting) { parent_meeting }
      leg
    end
  end
end
