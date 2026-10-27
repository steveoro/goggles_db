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

      # == Params:
      # - cup:             the GogglesDb::GoggleCup to read (required)
      # - roster_fallback: when true and no ranking_data is stored, returns a
      #                    synthesized roster instead of []: one zero-score entry
      #                    per enlisted swimmer (alphabetical, no top rows), each
      #                    carrying the swimmer's available base timings. Used for
      #                    published cups that were never computed.
      def initialize(cup, roster_fallback: false)
        @cup = cup
        @roster_fallback = roster_fallback
      end

      # Returns an array of ranking entries, ordered by overall score descending.
      # Each entry contains the swimmer info, the top-5 score rows and the base timings.
      def call
        data = parsed_data
        return (@roster_fallback ? roster_entries : []) if data.blank? || data['data'].blank?

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

      # Synthesized zero-score roster used when no ranking_data is stored:
      # one entry per enlisted swimmer, alphabetical by complete_name.
      def roster_entries
        GogglesDb::Swimmer.where(id: @cup.swimmer_ids_array)
                          .order(:complete_name)
                          .pluck(:id, :complete_name, :year_of_birth)
                          .map do |swimmer_id, complete_name, year_of_birth|
          {
            swimmer_id: swimmer_id,
            swimmer_name: complete_name,
            swimmer_year_of_birth: year_of_birth,
            overall_score: 0,
            top_rows: [],
            base_rows: roster_base_rows[swimmer_id] || []
          }
        end
      end

      def roster_base_rows
        @roster_base_rows ||= GogglesDb::GogglesCup3yBaseTimings
                              .where(swimmer_id: @cup.swimmer_ids_array)
                              .includes(:event_type, :pool_type, :meeting)
                              .group_by(&:swimmer_id)
                              .transform_values do |rows|
          rows.map do |row|
            ScoreRow.new(row.attributes.slice(*GogglesDb::GoggleCupRanking::DataSerializer::BASE_TIMING_COLUMNS))
          end
        end
      end
    end
  end
end
