# frozen_string_literal: true

module GogglesDb
  #
  # = HeatType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class HeatType < AbstractLookupEntity
    self.table_name = 'heat_types'

    # Unique IDs used inside the DB, the description will be retrieved using I18n.t
    HEAT_ID       = 1
    SEMIFINALS_ID = 2
    FINALS_ID     = 3

    # Instance variable names, mapped onto IDs (skipping ID=0):
    INSTANCE_VAR_NAMES = %w[_ heat semifinals finals].freeze

    # Commodity list of methods & constants that are expected to be "eventable":
    EVENTABLE_NAMES = %w[heat semifinals finals].freeze

    validates :code, presence: { length: { within: 1..10 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    class_eval do
      # [Steve, 20240213] Other rows with ID > 3 are basically unused since version 7
      first(3).each do |row|
        # Define a Memoized instance using the finder with the corresponding constant ID value:
        instance_variable_set(:"@#{INSTANCE_VAR_NAMES[row.id]}", row)

        # Define an helper class method to get the memoized value row:
        define_singleton_method(INSTANCE_VAR_NAMES[row.id].to_sym) do
          validate_cached_rows
          instance_variable_get(:"@#{INSTANCE_VAR_NAMES[row.id]}")
        end

        # Define an helper instance method that returns true if the ID corresponds to the word token:
        define_method(:"#{INSTANCE_VAR_NAMES[row.id]}?") do
          id == "#{self.class.name}::#{INSTANCE_VAR_NAMES[row.id].upcase}_ID".constantize
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # "Virtual" scope. Returns an Array of all "eventable" row types.
    def self.all_eventable
      EVENTABLE_NAMES.map { |word| instance_variable_get(:"@#{word}") }
    end
    #-- ------------------------------------------------------------------------
    #++

    # Checks the existence of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      INSTANCE_VAR_NAMES[1..].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with ID #{code_value}" if instance_variable_get(:"@#{word}").blank?
      end
    end
  end
end
