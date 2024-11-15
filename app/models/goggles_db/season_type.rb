# frozen_string_literal: true

module GogglesDb
  #
  # = SeasonType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class SeasonType < ApplicationRecord
    self.table_name = 'season_types'

    # Unique IDs used inside the DB:
    MAS_FIN_ID  = 1
    MAS_CSI_ID  = 2
    MAS_UISP_ID = 3
    AGO_FIN_ID  = 4
    AGO_CSI_ID  = 5
    AGO_UISP_ID = 6
    MAS_LEN_ID  = 7
    MAS_FINA_ID = 8

    belongs_to :federation_type
    validates_associated :federation_type

    default_scope { includes(:federation_type) }

    validates :code, presence: { length: { within: 1..10 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }
    validates :description, length: { maximum: 100 }
    validates :short_name, length: { maximum: 40 }

    # Returns +true+ if this Season type is Master-specific
    #--
    # NOTE: the following instance method must be defined before the metaprogramming below
    #++
    def masters?
      code.to_s.starts_with?('MAS')
    end

    # Returns the equivalent instance variable name as a string for the current row #code.
    def code_to_instance_var_name
      code.to_s.downcase.gsub(/^mas/, 'mas_').gsub(/^ago/, 'ago_')
    end
    #-- ------------------------------------------------------------------------
    #++

    class_eval do
      find_each do |row|
        # Define a Memoized instance using the finder with the corresponding constant ID value:
        instance_variable_set(:"@#{row.code_to_instance_var_name}", row)
        @all_masters ||= []
        @all_masters << row if row.masters?

        # Define an helper class method to get the memoized value row:
        define_singleton_method(row.code_to_instance_var_name.to_sym) do
          validate_cached_rows
          instance_variable_get(:"@#{row.code_to_instance_var_name}")
        end

        # Define an helper instance method that returns true if the ID corresponds to the word token:
        define_method(:"#{row.code_to_instance_var_name}?") do
          id == "#{self.class.name}::#{row.code_to_instance_var_name.upcase}_ID".constantize
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Virtual scope: array of memoized Masters-only Season types
    def self.all_masters # rubocop:disable Style/TrivialAccessors
      @all_masters
    end
    #-- ------------------------------------------------------------------------
    #++

    # Checks the existence of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[mas_fin mas_csi mas_uisp ago_fin ago_csi ago_uisp mas_len mas_fina].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with ID #{code_value}" if instance_variable_get(:"@#{word}").blank?
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
