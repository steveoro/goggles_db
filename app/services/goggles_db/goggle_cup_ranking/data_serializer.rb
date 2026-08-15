# frozen_string_literal: true

module GogglesDb
  module GoggleCupRanking
    # Serializes GoggleCup ranking data into a JSON-compatible structure
    # that can be stored in goggle_cups.ranking_data and later used to
    # reconstruct the ranking without rerunning the calculator.
    class DataSerializer
      BASE_TIMING_COLUMNS = %w[
        event_type_id event_type_code pool_type_id pool_type_code
        season_id season_header_year meeting_individual_result_id
        minutes seconds hundredths total_hundredths
        meeting_id meeting_date meeting_name team_id team_name
      ].freeze

      SCORE_COLUMNS = %w[
        event_type_id event_type_code pool_type_id pool_type_code
        season_id season_header_year meeting_individual_result_id
        minutes seconds hundredths total_hundredths
        meeting_id meeting_date meeting_name team_id team_name
        old_meeting_individual_result_id old_meeting_id old_meeting_date
        old_meeting_name old_total_hundredths old_minutes old_seconds old_hundredths
      ].freeze

      def initialize(cup:, ranking_data:, no_duplicated_events:)
        @cup = cup
        @ranking_data = ranking_data
        @no_duplicated_events = no_duplicated_events
      end

      def call
        {
          description: @cup.description,
          season_year: @cup.season_year,
          max_points: @cup.max_points,
          team_id: @cup.team_id,
          end_date: @cup.end_date&.iso8601,
          swimmer_ids: @cup.swimmer_ids_array,
          no_duplicated_events: @no_duplicated_events,
          data: {
            base_timings: base_timings_hash,
            scores: scores_hash
          }
        }
      end

      private

      def base_timings_hash
        swimmer_ids = @ranking_data.pluck(:swimmer_id)
        return {} if swimmer_ids.blank?

        GogglesDb::GogglesCup3yBaseTimings
          .where(swimmer_id: swimmer_ids)
          .includes(:event_type, :pool_type, :meeting)
          .group_by(&:swimmer_id)
          .transform_values do |rows|
            rows.map { |row| row.attributes.slice(*BASE_TIMING_COLUMNS) }
          end
      end

      def scores_hash
        @ranking_data.each_with_object({}) do |entry, hash|
          swimmer_id = entry[:swimmer_id]
          hash[swimmer_id.to_s] = entry[:top_rows].map do |top_row|
            row = top_row[:row]
            row.attributes.slice(*SCORE_COLUMNS).merge('row_score' => top_row[:row_score])
          end
        end
      end
    end
  end
end
