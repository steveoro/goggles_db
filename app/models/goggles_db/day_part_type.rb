# frozen_string_literal: true

module GogglesDb
  #
  # = DayPartType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7.030
  #   - authors:  Steve A.
  #
  class DayPartType < ApplicationLookupEntity
    self.table_name = 'day_part_types'

    # Unique IDs used inside the DB, the description will be retrieved using I18n.t
    MORNING_ID = 1
    AFTERNOON_ID = 2
    EVENING_ID = 3
    NIGHT_ID = 4

    validates :code, presence: { length: { maximum: 1 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    %w[morning afternoon evening night].each do |word|
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
      # (As in: def male? ; id == MALE_ID ; end )
      define_method("#{word}?".to_sym) { id == "#{self.class.name}::#{word.upcase}_ID".constantize }
    end

    # Checks the existance of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[morning afternoon evening night].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" unless instance_variable_get("@#{word}").present?
      end
    end
  end
end
