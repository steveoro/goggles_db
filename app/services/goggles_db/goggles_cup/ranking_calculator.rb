# frozen_string_literal: true

module GogglesDb
  module GogglesCup
    # = GogglesDb::GogglesCup::RankingCalculator
    #
    # Computes GogglesCup rankings from current-vs-previous best result rows.
    # (Ported from goggles_admin2's GogglesCup::RankingCalculator so that both
    # the API compute endpoint and the admin2 local preview share one engine
    # implementation.)
    class RankingCalculator
      def initialize(team_id:, swimmer_ids:, no_duplicated_events: false, rows: nil)
        @team_id = team_id
        @swimmer_ids = Array(swimmer_ids).compact_blank
        @no_duplicated_events = ActiveModel::Type::Boolean.new.cast(no_duplicated_events)
        @rows = rows
      end

      def call
        swimmer_scores = source_rows.group_by(&:swimmer_id).map do |swimmer_id, swimmer_rows|
          top_rows = best_rows_for(scored_rows_for(swimmer_rows))

          {
            swimmer_id: swimmer_id,
            swimmer_name: swimmer_rows.first.swimmer_name,
            swimmer_year_of_birth: swimmer_rows.first.swimmer_year_of_birth,
            overall_score: top_rows.sum { |scored_row| scored_row[:row_score] }.round(2),
            top_rows: top_rows
          }
        end

        swimmer_scores.sort_by { |data| -data[:overall_score] }
      end

      private

      def source_rows
        @source_rows ||= @rows || GogglesDb::BestSwimmerCurrentVsPreviousResult
                         .where(team_id: @team_id, swimmer_id: @swimmer_ids)
                         .includes(:event_type, :pool_type, :meeting)
      end

      def scored_rows_for(swimmer_rows)
        swimmer_rows.map do |row|
          {
            row: row,
            row_score: row_score_for(row)
          }
        end
      end

      def row_score_for(row)
        return 1000.0 unless row.old_total_hundredths.present? && row.old_total_hundredths.positive?

        (1000.0 * (row.old_total_hundredths.to_f / row.total_hundredths)).round(2)
      end

      def best_rows_for(scored_rows)
        rows = @no_duplicated_events ? best_row_per_event(scored_rows) : scored_rows

        rows.sort_by { |scored_row| -scored_row[:row_score] }.first(5)
      end

      def best_row_per_event(scored_rows)
        scored_rows
          .group_by { |scored_row| scored_row[:row].event_type_code }
          .values
          .map { |same_event_rows| same_event_rows.max_by { |scored_row| scored_row[:row_score] } }
      end
    end
  end
end
