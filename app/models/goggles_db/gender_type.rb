# frozen_string_literal: true

module GogglesDb
  #
  # = GenderType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7.000
  #   - author:   Steve A.
  #
  class GenderType < ApplicationRecord
    self.table_name = 'gender_types'

    # DB ID for 'Male' value (both for person or event)
    MALE_ID = 1
    # DB ID for 'Female' value (both for person or event)
    FEMALE_ID = 2
    # DB ID for 'Intermixed/Unspecified' value (both for person or event)
    INTERMIXED_ID = 3

    validates :code, presence: true, uniqueness: { case_sensitive: true, message: :already_exists }

    %w[male female intermixed].each do |word|
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
      %w[male female intermixed].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" unless instance_variable_get("@#{word}").present?
      end
    end
  end
end
