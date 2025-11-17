# frozen_string_literal: true

module GogglesDb
  #
  # = DataImportMeetingIndividualResult model
  #
  # Temporary storage for individual swimming results during data import phase 5.
  # Uses composite import_key for matching existing database rows.
  #
  # @author Steve A.
  #
  class DataImportMeetingIndividualResult < ApplicationRecord
    self.table_name = 'data_import_meeting_individual_results'

    include TimingManageable

    # Associations
    has_many :data_import_laps, foreign_key: :parent_import_key,
                                primary_key: :import_key, dependent: :delete_all,
                                inverse_of: :data_import_meeting_individual_result

    # ID references (not AR associations since these are temp tables)
    # - meeting_program_id
    # - swimmer_id
    # - team_id
    # - badge_id
    #
    # String key references (used when IDs are null - unmatched entities)
    # - swimmer_key: from phase3 (e.g., "ROSSI|Mario|1990")
    # - team_key: from phase2 (e.g., "ASD Team Name")
    # - meeting_program_key: program key (e.g., "1-100SL-M25-M")

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :swimmer_key, length: { maximum: 500 }, allow_nil: true
    validates :team_key, length: { maximum: 500 }, allow_nil: true
    validates :meeting_program_key, length: { maximum: 500 }, allow_nil: true
    validates :rank, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # Override minimal_attributes to add timing string
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s
      )
    end

    # Generates the import_key from components
    # Format: "program_key/swimmer_key"
    # Example: "1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI"
    def self.build_import_key(program_key, swimmer_key)
      "#{program_key}/#{swimmer_key}"
    end
  end
end
