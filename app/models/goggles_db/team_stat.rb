# frozen_string_literal: true

module GogglesDb
  #
  # = TeamStat parametric query wrapper
  #
  #   - version:  7-0.3.45
  #   - author:   Steve A.
  #   - build:    20220224
  #
  class TeamStat
    attr_reader :team, :sql, :results

    # Constructor: collects aggregated statistics for the specified team ID.
    #
    # == Params:
    # - team: a valid Team instance
    #
    # == Returns:
    # After construction, +results+ is an *Array* of Hash rows, with each Hash having the structure enlisted in the example below.
    #
    # == Usage examples:
    # > stats = GogglesDb::TeamStat.new(team)
    # > stats.results.count # (1 for each federation type)
    # => 5
    #
    # > ap stats.results.first
    # {
    #                   "federation_name" => "MASTER CSI",
    #                "first_meeting_data" => "2001-01-28:5:1A PROVA REGIONALE CSI:CSI",
    #                 "last_meeting_data" => "2019-11-10:19101:1A PROVA REGIONALE CSI:CSI",
    #                "affiliations_count" => 20,
    #                    "meetings_count" => 90,
    #                    "max_updated_at" => 2019-11-11 22:36:26 UTC,
    #
    #                     "first_meeting" => {
    #                "meeting_date" => "2001-01-28",
    #                  "meeting_id" => "5",
    #         "meeting_description" => "1A PROVA REGIONALE CSI",
    #             "federation_code" => "CSI"
    #     },
    #                     "last_meeting" => {
    #                "meeting_date" => "2019-11-10",
    #                  "meeting_id" => "19101",
    #         "meeting_description" => "1A PROVA REGIONALE CSI",
    #             "federation_code" => "CSI"
    #     }
    # }
    #
    # > stats.results.first['federation_name']
    # => "MASTER CSI"
    #
    def initialize(team)
      raise(ArgumentError, 'TeamStat: invalid team parameter!') unless team.is_a?(GogglesDb::Team)

      @team = team
      @sql = sql_query(team.id)
      @results = ActiveRecord::Base.connection.exec_query(@sql).to_a
      expand_results
    end

    private

    # Loops on all result rows and extracts concat()-ed string data into proper field names.
    # Updates the @results Array accordingly.
    def expand_results
      @results.each do |hash_row|
        split_data = hash_row['first_meeting_data'].split(':')
        add_subhash_for_meeting(hash_row, 'first_meeting', split_data)

        split_data = hash_row['last_meeting_data'].split(':')
        add_subhash_for_meeting(hash_row, 'last_meeting', split_data)
      end
    end

    # Adds a sub-Hash to the specified +hash+ using the <tt>subhash_key</tt> and the values
    # in <tt>values</tt> distributed according to this format:
    #
    # {
    #   'meeting_date' => values[0],
    #   'meeting_id' => values[1],
    #   'meeting_description' => values[2],
    #   'federation_code' => values[3]
    # }
    def add_subhash_for_meeting(hash, subhash_key, values)
      hash[subhash_key] = {
        'meeting_date' => values[0],
        'meeting_id' => values[1],
        'meeting_description' => values[2],
        'federation_code' => values[3]
      }
    end

    # Internal parametric query definition.
    #
    # == Params:
    # - team_id: the team id to filter on
    def sql_query(team_id)
      <<-SQL
        SELECT st.short_name AS federation_name,
          MIN(CONCAT(ms.scheduled_date, ':', ms.meeting_id, ':', m.description, ':', ft.code)) AS first_meeting_data,
          MAX(CONCAT(ms.scheduled_date, ':', ms.meeting_id, ':', m.description, ':', ft.code)) AS last_meeting_data,
          COUNT(DISTINCT ta.id) AS affiliations_count,
          COUNT(DISTINCT ms.meeting_id) AS meetings_count,
          MAX(mir.updated_at) AS max_updated_at
        FROM meeting_individual_results mir
          JOIN meeting_programs mp ON mp.id = mir.meeting_program_id
          JOIN meeting_events me ON me.id = mp.meeting_event_id
          JOIN meeting_sessions ms ON ms.id = me.meeting_session_id
          JOIN meetings m ON m.id = ms.meeting_id
          JOIN team_affiliations ta ON ta.id = mir.team_affiliation_id
          JOIN seasons s ON s.id = ta.season_id
          JOIN season_types st ON st.id = s.season_type_id
          JOIN federation_types ft ON ft.id = st.federation_type_id
        WHERE mir.team_id = #{team_id}
        GROUP BY st.short_name;
      SQL
    end
  end
end
