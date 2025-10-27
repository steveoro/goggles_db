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

    # Associations (via IDs, not actual AR associations since these are temp tables)
    # - meeting_program_id
    # - swimmer_id
    # - team_id
    # - badge_id

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
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
