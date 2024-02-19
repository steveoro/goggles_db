# frozen_string_literal: true

module GogglesDb
  #
  # = CoachLevelType model
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class CoachLevelType < AbstractLookupEntity
    self.table_name = 'coach_level_types'

    # Unique IDs used inside the DB, the description will be retrieved using I18n.t
    # (Assumes: all levels have been already seeded in order)
    MIN_LEVEL_ID = 1
    MAX_LEVEL_ID = 7

    validates :code, presence: { length: { within: 1..5 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }
    validates :level, presence: true, length: { within: 1..3, allow_nil: false },
                      numericality: true

    (MIN_LEVEL_ID..MAX_LEVEL_ID).each do |level_id|
      class_eval do
        # Define a Memoized instance using the finder with the corresponding constant ID value:
        instance_variable_set(:"@level_#{level_id}", find_by(id: level_id))
        # Define an helper class method to get the memoized value row:
        define_singleton_method(:"level_#{level_id}") do
          validate_cached_rows
          instance_variable_get(:"@level_#{level_id}")
        end
      end
    end

    # Checks the existence of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      (MIN_LEVEL_ID..MAX_LEVEL_ID).each do |level_id|
        raise "Missing required #{name} row with ID #{level_id}" if instance_variable_get(:"@level_#{level_id}").blank?
      end
    end
  end
end
