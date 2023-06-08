# frozen_string_literal: true

module GogglesDb
  #
  # = UserLap model
  #
  #   - version:  7-0.5.10
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

    has_one :gender_type, through: :swimmer
    has_one :user_workshop, through: :user_result
    has_one :event_type, through: :user_result
    has_one :pool_type,  through: :user_result
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      super + %w[user_workshop event_type pool_type user_result]
    end
    #-- ------------------------------------------------------------------------
    #++

    # AbstractLap overrides:
    alias_attribute :parent_meeting, :user_workshop # (old, new)
    alias_attribute :parent_result, :user_result
    alias_attribute :parent_result_id, :user_result_id
    alias user_workshop_attributes meeting_attributes # (new, old)

    # Returns the correct parent association symbol
    def self.parent_association_sym
      :user_result
    end

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
