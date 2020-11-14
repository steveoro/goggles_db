# frozen_string_literal: true

module GogglesDb
  #
  # = StrokeType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class StrokeType < ApplicationLookupEntity
    self.table_name = 'stroke_types'

    # Unique IDs used inside the DB, the description will be retrieved using I18n.t
    FREESTYLE_ID    = 1 # both individual & relays
    BUTTERFLY_ID    = 2
    BACKSTROKE_ID   = 3
    BREASTSTROKE_ID = 4
    INTERMIXED_ID   = 5 # only for individual intermixed style
    EXE_STARTING_ID = 6 # specific exercises
    EXE_LAPTURNS_ID = 7
    EXE_POWER_ID    = 8
    EXE_GENERIC_ID  = 9
    REL_INTERMIXED_ID = 10 # only for intermixed relays

    # Commodity list of methods & constants that are expected to be "eventable":
    EVENTABLE_NAMES = %w[freestyle butterfly backstroke breaststroke intermixed rel_intermixed].freeze

    alias_attribute :eventable?, :is_eventable

    validates :code, presence: { length: { within: 1..2 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    %w[freestyle butterfly backstroke breaststroke intermixed
       exe_starting exe_lapturns exe_power exe_generic rel_intermixed].each do |word|
      class_eval do
        # Define a Memoized instance using the finder with the corresponding constant ID value:
        instance_variable_set("@#{word}", find_by(id: "#{name}::#{word.upcase}_ID".constantize))
        # Define an helper class method to get the memoized value row:
        define_singleton_method(word.to_sym) do
          validate_cached_rows
          instance_variable_get("@#{word}")
        end
      end
      # Define an helper class method that returns true if the ID corresponds to the word token:
      define_method("#{word}?".to_sym) { id == "#{self.class.name}::#{word.upcase}_ID".constantize }
    end

    # "Virtual" scope. Returns an Array of all eventable row types.
    #--
    # NOTE:
    # This is way faster then an actual scope, like the one in previous implementations:
    #
    #   scope :eventable, -> { where(is_eventable: true) }
    #
    # Although the result is not a relation, the memoized version doesn't need to issue a query.
    #++
    def self.eventable
      EVENTABLE_NAMES.map { |word| instance_variable_get("@#{word}") }
    end
    #-- ------------------------------------------------------------------------
    #++

    # Checks the existance of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[freestyle butterfly backstroke breaststroke intermixed
         exe_starting exe_lapturns exe_power exe_generic rel_intermixed].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" unless instance_variable_get("@#{word}").present?
      end
    end
  end
end
