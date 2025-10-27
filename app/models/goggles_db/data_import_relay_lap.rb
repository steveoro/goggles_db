# frozen_string_literal: true

module GogglesDb
  #
  # = DataImportRelayLap model
  #
  # Temporary storage for relay result lap timings during data import phase 5.
  # Uses composite import_key for matching existing database rows.
  #
  # @author Steve A.
  #
  class DataImportRelayLap < ApplicationRecord
    self.table_name = 'data_import_relay_laps'

    include TimingManageable

    # Parent relationship (via import_key, not AR association)
    # - parent_import_key => DataImportMeetingRelayResult.import_key
    # - meeting_relay_result_id

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :parent_import_key, presence: true, length: { maximum: 500 }
    validates :length_in_meters, presence: true, numericality: { only_integer: true, greater_than: 0 }

    # Override minimal_attributes to add timing string
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s
      )
    end

    # Generates the import_key from components
    # Format: "mrr_key/length_in_meters"
    # Example: "1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67/50"
    def self.build_import_key(mrr_import_key, length_in_meters)
      "#{mrr_import_key}/#{length_in_meters}"
    end
  end
end
