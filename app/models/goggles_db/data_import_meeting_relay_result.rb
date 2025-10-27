# frozen_string_literal: true

module GogglesDb
  #
  # = DataImportMeetingRelayResult model
  #
  # Temporary storage for relay team results during data import phase 5.
  # Uses composite import_key for matching existing database rows.
  #
  # @author Steve A.
  #
  class DataImportMeetingRelayResult < ApplicationRecord
    self.table_name = 'data_import_meeting_relay_results'

    # Associations (via IDs, not actual AR associations)
    # - meeting_program_id
    # - team_id
    # - team_affiliation_id

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :rank, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # Returns the timing as a Timing instance
    def to_timing
      @to_timing ||= Timing.new(hundredths: hundredths || 0, seconds: seconds || 0, minutes: minutes || 0)
    end

    # Override minimal_attributes to add timing string
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s,
        'relay_code' => relay_code || ''
      )
    end

    # Generates the import_key from components
    # Format: "program_key/team_key-timing"
    # Example: "1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67"
    def self.build_import_key(program_key, team_key, timing_string)
      "#{program_key}/#{team_key}-#{timing_string || '0'}"
    end

    # Truncate all records
    def self.truncate!
      connection.truncate(table_name)
    end
  end
end
