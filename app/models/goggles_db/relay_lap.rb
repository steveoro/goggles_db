# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = RelayLap model
  #
  #   - version:  7-0.6.10
  #   - author:   Steve A.
  #
  # == Note:
  # This model is designed to be used only whenever "sub-fractional" lap timings in
  # long relay fractions are available for storage (e.g., in 4x100m or 4x200m).
  #
  # In these cases, if the intermediate timings are available (for each 25 or 50 m.), use:
  # - parent MeetingRelayResult  => overall relay timings
  # - parent MeetingRelaySwimmer => final fraction timings (i.e.: 100m or 200m)
  # - linked RelayLap => each available lap timing except the last one (i.e.: each 25 or 50 m.)
  #
  # This is also the same lap recording protocol used for MIRs & Laps.
  class RelayLap < AbstractLap
    self.table_name = 'relay_laps'

    belongs_to :swimmer
    belongs_to :team
    belongs_to :meeting_relay_result
    belongs_to :meeting_relay_swimmer

    validates_associated :swimmer
    validates_associated :team
    validates_associated :meeting_relay_result
    validates_associated :meeting_relay_swimmer

    has_one :meeting,         through: :meeting_relay_result
    has_one :meeting_program, through: :meeting_relay_result
    has_one :event_type,      through: :meeting_relay_result
    has_one :category_type,   through: :meeting_relay_result
    has_one :gender_type,     through: :swimmer
    has_one :pool_type,       through: :meeting_relay_result

    validates :stroke_cycles, length: { within: 1..3 }, allow_nil: true
    validates :breath_cycles, length: { within: 1..3 }, allow_nil: true
    validates :position,      length: { within: 1..4 }, allow_nil: true

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      super + %w[swimmer team meeting meeting_program event_type category_type
                 meeting_relay_result meeting_relay_swimmer]
    end
    #-- ------------------------------------------------------------------------
    #++

    # AbstractLap overrides:
    alias_attribute :parent_meeting, :meeting
    alias_attribute :parent_result, :meeting_relay_swimmer
    alias_attribute :parent_result_id, :meeting_relay_swimmer_id

    # Returns the correct parent association symbol
    def self.parent_association_sym
      :meeting_relay_swimmer
    end

    # Returns the column symbol used for the parent association with a result row
    def self.parent_result_column_sym
      :meeting_relay_swimmer_id
    end

    # Returns the association "where" condition for the parent result row.
    def parent_result_where_condition
      { meeting_relay_swimmer_id: }
    end
  end
end
