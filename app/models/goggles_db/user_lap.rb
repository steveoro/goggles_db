# frozen_string_literal: true

module GogglesDb
  #
  # = UserLap model
  #
  #   - version:  7.02.18
  #   - author:   Steve A.
  #
  # User laps refer exclusively to user results (& user workshops)
  #
  class UserLap < AbstractLap
    self.table_name = 'user_laps'

    belongs_to :user_result
    belongs_to :swimmer
    validates_associated :user_result
    validates_associated :swimmer

    has_one :user_workshop, through: :user_result
    has_one :event_type, through: :user_result
    has_one :pool_type,  through: :user_result
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      # [Steve A.] Using the safe-access operator where there are no actual foreign keys:
      attributes.merge(
        'timing' => to_timing.to_s,
        'timing_from_start' => timing_from_start.to_s,
        'swimmer' => swimmer_attributes,
        'user_workshop' => meeting_attributes,
        'user_result' => user_result.minimal_attributes,
        'event_type' => event_type&.lookup_attributes,
        'pool_type' => pool_type&.lookup_attributes
      ).to_json(options)
    end
    #-- ------------------------------------------------------------------------
    #++

    # AbstractLap overrides:
    alias_attribute :parent_meeting, :user_workshop # (old, new)
    alias_attribute :parent_result_id, :user_result_id
    alias user_workshop_attributes meeting_attributes # (new, old)

    # Returns the column symbol used for the parent association with a result row
    def self.parent_result_column_sym
      :user_result_id
    end

    # Returns the association "where" condition for the parent result row.
    def parent_result_where_condition
      { user_result_id: user_result_id }
    end
  end
end
