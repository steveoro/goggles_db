# frozen_string_literal: true

module GogglesDb
  #
  # = MedalType model
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class MedalType < AbstractLookupEntity
    self.table_name = 'medal_types'

    # Unique IDs used inside the DB, the description will be retrieved using I18n.t
    GOLD_ID   = 1
    SILVER_ID = 2
    BRONZE_ID = 3
    WOOD_ID   = 4

    # Commodity list of methods & constants that are expected to be "eventable":
    EVENTABLE_NAMES = %w[gold silver bronze].freeze

    validates :code, presence: { length: { maximum: 1 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    %w[gold silver bronze wood].each do |word|
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

    # "Virtual" scope. Returns an Array of all eventable row types.
    def self.all_eventable
      EVENTABLE_NAMES.map { |word| instance_variable_get(:"@#{word}") }
    end
    #-- ------------------------------------------------------------------------
    #++

    # QUICK FIX for ugly typo in legacy structure.sql:
    alias_attribute :weight, :weigth

    # Returns +true+ if the "weight" of the medal will affect the overall event score
    def eventable?
      weight.positive?
    end
    #-- ------------------------------------------------------------------------
    #++

    # Checks the existance of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[gold silver bronze wood].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" if instance_variable_get(:"@#{word}").blank?
      end
    end
  end
end
