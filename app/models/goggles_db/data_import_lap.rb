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

    # Parent relationship (via import_key, not AR association)
    # - parent_import_key => DataImportMeetingIndividualResult.import_key
    # - meeting_individual_result_id

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :parent_import_key, presence: true, length: { maximum: 500 }
    validates :length_in_meters, presence: true, numericality: { only_integer: true, greater_than: 0 }

    # Returns the timing as a Timing instance
    def to_timing
      @to_timing ||= Timing.new(hundredths: hundredths || 0, seconds: seconds || 0, minutes: minutes || 0)
    end

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

    # Truncate all records
    def self.truncate!
      connection.truncate(table_name)
    end
  end
end
