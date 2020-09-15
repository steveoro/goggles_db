# frozen_string_literal: true

module GogglesDb
  #
  # = SeasonType model
  #
  # This entity is assumed to be pre-seeded on the database.
  # Due to the low number of entity values, all rows have been Memoized.
  #
  #   - version:  7.000
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
    validates :federation_type, presence: true
    validates_associated :federation_type

    validates :code, presence: { length: { within: 1..10 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }
    validates :description, length: { maximum: 100 }
    validates :short_name, length: { maximum: 40 }

    %w[mas_fin mas_csi mas_uisp ago_fin ago_csi ago_uisp mas_len mas_fina].each do |word|
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

    # Checks the existance of all the required value rows; raises an error for any missing row.
    def self.validate_cached_rows
      %w[mas_fin mas_csi mas_uisp ago_fin ago_csi ago_uisp mas_len mas_fina].each do |word|
        code_value = "#{name}::#{word.upcase}_ID".constantize
        raise "Missing required #{name} row with code #{code_value}" unless instance_variable_get("@#{word}").present?
      end
    end
  end
end
