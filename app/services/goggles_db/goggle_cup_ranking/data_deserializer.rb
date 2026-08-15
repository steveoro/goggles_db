# frozen_string_literal: true

module GogglesDb
  module GoggleCupRanking
    # Deserializes the JSON structure stored in goggle_cups.ranking_data back
    # into the array-of-hashes structure expected by the shared ranking partial,
    # wrapping each stored row hash in a ScoreRow so the partial can use dot-access.
    # The returned entries also include the base timings used for each swimmer.
    class DataDeserializer
      # Lightweight wrapper that delegates method calls to hash keys.
      class ScoreRow
        def initialize(hash)
          @hash = hash || {}
        end

        def method_missing(name, *args)
          return @hash[name.to_s] if @hash.key?(name.to_s)

          super
        end

        def respond_to_missing?(name, include_private = false)
          @hash.key?(name.to_s) || super
        end
      end

      def initialize(cup)
        @cup = cup
      end

      # Returns an array of ranking entries, ordered by overall score descending.
      # Each entry contains the swimmer info, the top-5 score rows and the base timings.
      def call
        data = parsed_data
        return [] if data.blank? || data['data'].blank?

        scores = data['data']['scores'] || {}
        base_timings = data['data']['base_timings'] || {}
        swimmer_names = fetch_swimmer_names(scores.keys)

        entries = scores.map do |swimmer_id_str, rows|
          build_entry(swimmer_id_str, rows, base_timings[swimmer_id_str], swimmer_names)
        end
        sort_by_score(entries)
      end

      private

      def build_entry(swimmer_id_str, rows, base_rows, swimmer_names)
        swimmer_id = swimmer_id_str.to_i
        swimmer_info = swimmer_names[swimmer_id] || ['', nil]
        top_rows = build_top_rows(rows)
        {
          swimmer_id: swimmer_id,
          swimmer_name: swimmer_info[0],
          swimmer_year_of_birth: swimmer_info[1],
          overall_score: top_rows.sum { |tr| tr[:row_score].to_f }.round(2),
          top_rows: top_rows,
          base_rows: build_base_rows(base_rows)
        }
      end

      def build_top_rows(rows)
        Array(rows).map do |row_hash|
          {
            row: ScoreRow.new(row_hash),
            row_score: row_hash['row_score']
          }
        end
      end

      def build_base_rows(rows)
        Array(rows).map { |row_hash| ScoreRow.new(row_hash) }
      end

      def sort_by_score(entries)
        entries.sort_by { |entry| -entry[:overall_score] }
      end

      def parsed_data
        raw = @cup.ranking_data
        return {} if raw.blank?

        raw.is_a?(String) ? JSON.parse(raw) : raw
      end

      def fetch_swimmer_names(ids)
        return {} if ids.blank?

        GogglesDb::Swimmer.where(id: ids.map(&:to_i))
                          .pluck(:id, :complete_name, :year_of_birth)
                          .to_h do |row|
          [row[0], [row[1], row[2]]]
        end
      end
    end
  end
end
