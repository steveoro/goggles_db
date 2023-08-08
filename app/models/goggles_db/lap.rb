# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = Lap model
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  # == Note:
  # Lap is currently dedicated to MIRs *only*: use MeetingRelaySwimmer (MRS)
  # to store lap data for MRRs.
  #
  class Lap < AbstractLap
    self.table_name = 'laps'

    # [Steve A.] These 3 are actually optional but always "filled by hand":
    belongs_to :meeting_program
    belongs_to :swimmer
    belongs_to :team
    validates_associated :meeting_program
    validates_associated :swimmer
    validates_associated :team

    belongs_to :meeting_individual_result
    validates_associated :meeting_individual_result

    has_one :meeting,       through: :meeting_program
    has_one :event_type,    through: :meeting_program
    has_one :category_type, through: :meeting_program
    has_one :gender_type,   through: :meeting_program
    has_one :pool_type,     through: :meeting_program

    validates :stroke_cycles, length: { within: 1..3 }, allow_nil: true
    validates :breath_cycles, length: { within: 1..3 }, allow_nil: true
    validates :position,      length: { within: 1..4 }, allow_nil: true

    validates :underwater_kicks,    length: { within: 1..3 }, allow_nil: true
    validates :underwater_seconds,  length: { within: 1..2 }, allow_nil: true
    validates :underwater_hundredths, length: { within: 1..2 }, allow_nil: true
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      super + %w[team meeting meeting_program event_type category_type meeting_individual_result]
    end
    #-- ------------------------------------------------------------------------
    #++

    # AbstractLap overrides:
    alias_attribute :parent_meeting, :meeting
    alias_attribute :parent_result, :meeting_individual_result
    alias_attribute :parent_result_id, :meeting_individual_result_id

    # Returns the correct parent association symbol
    def self.parent_association_sym
      :meeting_individual_result
    end

    # Returns the column symbol used for the parent association with a result row
    def self.parent_result_column_sym
      :meeting_individual_result_id
    end

    # Returns the association "where" condition for the parent result row.
    def parent_result_where_condition
      { meeting_individual_result_id: }
    end
  end
end
