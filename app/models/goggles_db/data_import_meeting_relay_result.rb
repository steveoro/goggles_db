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

    include TimingManageable

    # Associations
    has_many :data_import_relay_laps, foreign_key: :parent_import_key,
                                      primary_key: :import_key, dependent: :delete_all,
                                      inverse_of: :data_import_meeting_relay_result
    has_many :data_import_meeting_relay_swimmers, foreign_key: :parent_import_key,
                                                  primary_key: :import_key, dependent: :delete_all,
                                                  inverse_of: :data_import_meeting_relay_result

    # ID references (not AR associations since these are temp tables)
    # - meeting_program_id
    # - team_id
    # - team_affiliation_id
    #
    # String key references (used when IDs are null - unmatched entities)
    # - team_key: from phase2 (e.g., "ASD Team Name")
    # - meeting_program_key: program key (e.g., "1-4X50SL-M100-F")

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :team_key, length: { maximum: 500 }, allow_nil: true
    validates :meeting_program_key, length: { maximum: 500 }, allow_nil: true
    validates :rank, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

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
  end
end
