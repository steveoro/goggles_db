# frozen_string_literal: true

module GogglesDb
  #
  # = DataImportLap model
  #
  # Temporary storage for individual result lap timings during data import phase 5.
  # Uses composite import_key for matching existing database rows.
  #
  # @author Steve A.
  #
  class DataImportLap < ApplicationRecord
    self.table_name = 'data_import_laps'

    include TimingManageable

    # Associations
    belongs_to :data_import_meeting_individual_result, foreign_key: :parent_import_key,
                                                       primary_key: :import_key, optional: true,
                                                       inverse_of: :data_import_laps

    # ID reference (for final database row, not AR association)
    # - meeting_individual_result_id
    #
    # String key references (used for parent reference)
    # - meeting_individual_result_key: parent MIR import_key reference

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :meeting_individual_result_key, length: { maximum: 500 }, allow_nil: true
    validates :parent_import_key, presence: true, length: { maximum: 500 }
    validates :length_in_meters, presence: true, numericality: { only_integer: true, greater_than: 0 }

    # Override minimal_attributes to add timing string
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s
      )
    end

    # Generates the import_key from components
    # Format: "mir_key/length_in_meters"
    # Example: "1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI/50"
    def self.build_import_key(mir_import_key, length_in_meters)
      "#{mir_import_key}/#{length_in_meters}"
    end
  end
end
