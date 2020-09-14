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

    # Memoized instances:
    @male = find_by(id: MALE_ID)
    @female = find_by(id: FEMALE_ID)
    @intermixed = find_by(id: INTERMIXED_ID)

    validates :code, presence: true, uniqueness: { case_sensitive: true, message: :already_exists }

    # Returns the "male" entity row
    def self.male
      validate_cached_rows
      @male
    end

    # Returns the "female" entity row
    def self.female
      validate_cached_rows
      @female
    end

    # Returns the "intermixed" entity row
    def self.intermixed
      validate_cached_rows
      @intermixed
    end

    # Returns true for a MALE_ID
    def male?
      (id == MALE_ID)
    end

    # Returns true for a FEMALE_ID
    def female?
      (id == FEMALE_ID)
    end

    # Checks the existance of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[male female intermixed].each do |word|
        code_value = "GogglesDb::GenderType::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" unless instance_variable_get("@#{word}").present?
      end
    end
  end
end
