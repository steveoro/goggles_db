# frozen_string_literal: true

module GogglesDb
  #
  # = EditionType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class EditionType < AbstractLookupEntity
    self.table_name = 'edition_types'

    # Unique IDs used inside the DB:
    ORDINAL_ID  = 1
    ROMAN_ID    = 2
    NONE_ID     = 3
    YEARLY_ID   = 4
    SEASONAL_ID = 5

    validates :code, presence: { length: { maximum: 1 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    %w[ordinal roman none yearly seasonal].each do |word|
      class_eval do
        # Define a Memoized instance using the finder with the corresponding constant ID value:
        instance_variable_set(:"@#{word}", find_by(id: "#{name}::#{word.upcase}_ID".constantize))
        # Define an helper class method to get the memoized value row:
        define_singleton_method(word.to_sym) do
          validate_cached_rows
          instance_variable_get(:"@#{word}")
        end
      end
      # Define an helper instance method that returns true if the ID corresponds to the word token:
      define_method(:"#{word}?") { id == "#{self.class.name}::#{word.upcase}_ID".constantize }
    end

    # Checks the existance of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[ordinal roman none yearly seasonal].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" if instance_variable_get(:"@#{word}").blank?
      end
    end
  end
end
