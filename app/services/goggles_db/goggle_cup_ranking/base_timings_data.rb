# frozen_string_literal: true

module GogglesDb
  module GoggleCupRanking
    # Prepares base-timings data for rendering or export.
    #
    # Sorts by swimmer name and drops any swimmer with no base rows,
    # keeping the existing ordering of each swimmer's base rows.
    class BaseTimingsData
      def initialize(ranking_data)
        @ranking_data = ranking_data || []
      end

      def call
        @ranking_data
          .reject { |data| data[:base_rows].blank? }
          .sort_by { |data| data[:swimmer_name].to_s }
      end
    end
  end
end
