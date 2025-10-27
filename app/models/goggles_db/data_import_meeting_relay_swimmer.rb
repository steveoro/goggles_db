# frozen_string_literal: true

module GogglesDb
  #
  # = DataImportMeetingRelaySwimmer model
  #
  # Temporary storage for individual swimmers within relay teams during data import phase 5.
  # Uses composite import_key for matching existing database rows.
  #
  # @author Steve A.
  #
  class DataImportMeetingRelaySwimmer < ApplicationRecord
    self.table_name = 'data_import_meeting_relay_swimmers'

    # Parent relationship (via import_key, not AR association)
    # - parent_import_key => DataImportMeetingRelayResult.import_key
    # - meeting_relay_result_id
    # - swimmer_id
    # - badge_id

    validates :import_key, presence: true, uniqueness: true, length: { maximum: 500 }
    validates :parent_import_key, presence: true, length: { maximum: 500 }
    validates :relay_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 4 }

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
    # Format: "mrs{order}-mrr_key-swimmer_key"
    # Example: "mrs1-1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67-ROSSI-1978-M-CSI OBER FERRARI"
    def self.build_import_key(order, mrr_import_key, swimmer_key)
      "mrs#{order}-#{mrr_import_key}-#{swimmer_key}"
    end
  end
end
