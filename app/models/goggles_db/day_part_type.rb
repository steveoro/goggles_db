# frozen_string_literal: true

module GogglesDb
  #
  # = DayPartType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7-0.6.30
  #   - authors:  Steve A.
  #
  class DayPartType < AbstractLookupEntity
    self.table_name = 'day_part_types'

    # Unique IDs used inside the DB, the description will be retrieved using I18n.t
    MORNING_ID = 1
    AFTERNOON_ID = 2
    EVENING_ID = 3
    NIGHT_ID = 4

    # Instance variable names, mapped onto IDs (skipping ID=0):
    INSTANCE_VAR_NAMES = %w[_ morning afternoon evening night].freeze

    validates :code, presence: { length: { maximum: 1 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    class_eval do
      all.find_each do |row|
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

    # Checks the existence of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      INSTANCE_VAR_NAMES[1..].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with ID #{code_value}" if instance_variable_get(:"@#{word}").blank?
      end
    end
  end
end
