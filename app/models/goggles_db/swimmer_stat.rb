# frozen_string_literal: true

module GogglesDb
  #
  # = SwimmerStat parametric query wrapper
  #
  #   - version:  7-0.3.45
  #   - author:   Steve A.
  #   - build:    20220224
  #
  class SwimmerStat
    attr_reader :swimmer, :sql, :result

    # Constructor
    # == Params:
    # - swimmer: a valid Swimmer instance
    #
    # == Returns:
    # After construction, +result+ is a single Hash having the structure enlisted in the example below.
    #
    # == Usage examples:
    # > stats = GogglesDb::SwimmerStat.new(swimmer)
    # > stats.result.class
    # => Hash
    #
    # > ap stats.result
    # {
    #                   "meetings_count" => 177,
    #                 "individual_count" => 368,
    #                 "total_fin_points" => 142080.46,
    #               "individual_minutes" => 155,
    #               "individual_seconds" => 10725,
    #            "individual_hundredths" => 17486,
    #                "individual_meters" => 26600,
    #    "individual_disqualified_count" => 1,
    #              "max_fin_points_data" => "876.67:18211:50RA:2019-06-28:FIN:CAMPIONATI ITALIANI FIN",
    #              "min_fin_points_data" => "673.37:18:50FA:2004-03-06:FIN:MEETING CITTA' DI SAN MARINO",
    #                      "irons_count" => 0,
    #               "teams_name_and_ids" => "CSI NUOTO OBER FERRARI ASD:1, REGGIANA NUOTO:224",
    #               "first_meeting_data" => "2002-12-15:6:1A PROVA REGIONALE CSI:CSI",
    #                "last_meeting_data" => "2020-01-12:19243:18^ Trofeo Citta' di Ravenna:FIN",
    #                     "relays_count" => 50,
    #                    "relay_minutes" => 4,
    #                    "relay_seconds" => 1349,
    #                 "relay_hundredths" => 1944,
    #                     "relay_meters" => 2700,
    #         "relay_disqualified_count" => 1,
    #                    "current_teams" => nil,
    #               "current_categories" => nil,
    #
    #                   "max_fin_points" => {
    #             "standard_points" => "876.67",
    #                  "meeting_id" => "18211",
    #                  "event_code" => "50RA",
    #                  "event_date" => "2019-06-28",
    #             "federation_code" => "FIN",
    #         "meeting_description" => "CAMPIONATI ITALIANI FIN"
    #     },
    #                   "min_fin_points" => {
    #             "standard_points" => "673.37",
    #                  "meeting_id" => "18",
    #                  "event_code" => "50FA",
    #                  "event_date" => "2004-03-06",
    #             "federation_code" => "FIN",
    #         "meeting_description" => "MEETING CITTA' DI SAN MARINO"
    #     },
    #                             "teams" => [
    #         [0] #<GogglesDb::Team:0x0000564fb8e76b30> {
    #                         :id => 1,
    #                       :name => "CSI NUOTO OBER FERRARI ASD",
    #             # [...snip...]
    #         },
    #         [1] #<GogglesDb::Team:0x0000564fb8dc86e8> {
    #                         :id => 224,
    #               :lock_version => 0,
    #                       :name => "REGGIANA NUOTO",
    #             # [...snip...]
    #         }
    #     ],
    #                     "first_meeting" => {
    #                "meeting_date" => "2002-12-15",
    #                  "meeting_id" => "6",
    #         "meeting_description" => "1A PROVA REGIONALE CSI",
    #             "federation_code" => "CSI"
    #     },
    #                     "last_meeting" => {
    #                "meeting_date" => "2020-01-12",
    #                  "meeting_id" => "19243",
    #         "meeting_description" => "18^ Trofeo Citta' di Ravenna",
    #             "federation_code" => "FIN"
    #     }
    # }
    #
    # > stats.results['meetings_count'] # (all attended Meetings over time)
    # => 177
    #
    # > stats.results['teams'].count # (all Teams to which the Swimmer has participated over time)
    # => 2
    #
    def initialize(swimmer)
      raise(ArgumentError, 'SwimmerStat: invalid swimmer parameter!') unless swimmer.is_a?(GogglesDb::Swimmer)

      @swimmer = swimmer
      @sql = sql_query(swimmer.id)
      # A single row result is expected here:
      @result = ActiveRecord::Base.connection.exec_query(@sql).to_a.first
      expand_result
    end

    private

    # Loops on all result rows and extracts concat()-ed string data into proper field names.
    # Updates the @result Hash accordingly.
    def expand_result
      split_data = @result['max_fin_points_data'].split(':')
      add_subhash_for_points(@result, 'max_fin_points', split_data)

      split_data = @result['min_fin_points_data'].split(':')
      add_subhash_for_points(@result, 'min_fin_points', split_data)

      split_data = @result['teams_name_and_ids'].split(',')
      @result['teams'] = split_data.map do |token|
        team_id = token.split(':').last.to_i
        GogglesDb::Team.find(team_id) if team_id.positive?
      end
      @result['teams'].compact!

      split_data = @result['first_meeting_data'].split(':')
      add_subhash_for_meeting(@result, 'first_meeting', split_data)

      split_data = @result['last_meeting_data'].split(':')
      add_subhash_for_meeting(@result, 'last_meeting', split_data)
    end

    # Adds a sub-Hash to the specified +hash+ using the <tt>subhash_key</tt> and the values
    # in <tt>values</tt> distributed according to this format:
    #
    # {
    #   'standard_points' => values[0],
    #   'meeting_id' => values[1],
    #   'event_code' => values[2],
    #   'event_date' => values[3],
    #   'federation_code' => values[4],
    #   'meeting_description' => values[5]
    # }
    def add_subhash_for_points(hash, subhash_key, values)
      hash[subhash_key] = {
        'standard_points' => values[0],
        'meeting_id' => values[1],
        'event_code' => values[2],
        'event_date' => values[3],
        'federation_code' => values[4],
        'meeting_description' => values[5]
      }
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
    # - swimmer_id: the swimmer id to filter on
    def sql_query(swimmer_id)
      <<-SQL
        SELECT
          SUM(sbs.meeting_count) AS meetings_count,
          SUM(sbs.mir_count) AS individual_count,
          SUM(CASE WHEN sbs.fed_code = 'FIN' THEN sbs.total_points ELSE 0 END) AS total_fin_points,
          SUM(sbs.individual_minutes) AS individual_minutes,
          SUM(sbs.individual_seconds) AS individual_seconds,
          SUM(sbs.individual_hundredths) AS individual_hundredths,
          SUM(sbs.individual_meters) AS individual_meters,
          SUM(sbs.individual_disqualified_count) AS individual_disqualified_count,
          MAX(sbs.max_points) AS max_fin_points_data,
          MIN(CASE WHEN sbs.fed_code = 'FIN' AND substr(sbs.min_points, 1, 4) <> '0.00' THEN sbs.min_points ELSE '9999:99999999' END) AS min_fin_points_data,
          SUM(CASE WHEN sbs.fed_code = 'FIN' AND sbs.event_count >= 18 THEN 1 ELSE 0 END) AS irons_count,
          GROUP_CONCAT(DISTINCT sbs.team_name_and_id separator ', ') AS teams_name_and_ids,
          MIN(sbs.min_date) AS first_meeting_data,
          MAX(sbs.max_date) AS last_meeting_data,
          SUM(sbr.mrr_count) AS relays_count,
          SUM(sbr.relay_minutes) AS relay_minutes,
          SUM(sbr.relay_seconds) AS relay_seconds,
          SUM(sbr.relay_hundredths) AS relay_hundredths,
          SUM(sbr.relay_meters) AS relay_meters,
          SUM(sbr.relay_disqualified_count) AS relay_disqualified_count,
          GROUP_CONCAT(crb.current_team separator ', ') AS current_teams,
          GROUP_CONCAT(crb.current_category separator ', ') AS current_categories
        -- Individual results
        FROM (
          SELECT mir.swimmer_id, mir.badge_id, ft.code AS fed_code,
          CONCAT(t.editable_name, ':', t.id) AS team_name_and_id,
            COUNT(DISTINCT ms.meeting_id) AS meeting_count,
            COUNT(mir.id) AS mir_count,
            SUM(mir.standard_points) AS total_points,
            SUM(mir.minutes) AS individual_minutes,
            SUM(mir.seconds) AS individual_seconds,
            SUM(mir.hundredths) AS individual_hundredths,
            SUM(et.length_in_meters) AS individual_meters,
            SUM(mir.disqualified) AS individual_disqualified_count,
            MAX(CONCAT(mir.standard_points, ':', m.id, ':', et.code, ':', ms.scheduled_date, ':', ft.code, ':', m.description)) AS max_points,
            MIN(CONCAT(mir.standard_points, ':', m.id, ':', et.code, ':', ms.scheduled_date, ':', ft.code, ':', m.description)) AS min_points,
            COUNT(DISTINCT et.code) AS event_count,
          MIN(CONCAT(ms.scheduled_date, ':', m.id, ':', m.description, ':', ft.code)) AS min_date,
          MAX(CONCAT(ms.scheduled_date, ':', m.id, ':', m.description, ':', ft.code)) AS max_date
          FROM meeting_individual_results mir
            JOIN meeting_programs mp ON mp.id = mir.meeting_program_id
            JOIN meeting_events me ON me.id = mp.meeting_event_id
            JOIN meeting_sessions ms ON ms.id = me.meeting_session_id
            JOIN category_types ct ON ct.id = mp.category_type_id
            JOIN event_types et ON et.id = me.event_type_id
            JOIN meetings m ON m.id = ms.meeting_id
            JOIN seasons s ON s.id = m.season_id
            JOIN season_types st ON st.id = s.season_type_id
            JOIN federation_types ft ON ft.id = st.federation_type_id
            JOIN badges b ON b.id = mir.badge_id
            JOIN teams t ON t.id = b.team_id
          WHERE mir.swimmer_id = #{swimmer_id}
          GROUP BY mir.swimmer_id, mir.badge_id, ft.code, CONCAT(t.editable_name, ':', t.id)
        ) AS sbs
        -- Relays
        LEFT JOIN (
          SELECT mrs.swimmer_id, mrs.badge_id,
            COUNT(mrr.id) AS mrr_count,
            SUM(mrs.minutes) AS relay_minutes,
            SUM(mrs.seconds) AS relay_seconds,
            SUM(mrs.hundredths) AS relay_hundredths,
            SUM(et.phase_length_in_meters) AS relay_meters,
            SUM(mrr.disqualified) AS relay_disqualified_count
          FROM meeting_relay_swimmers mrs
            JOIN meeting_relay_results mrr ON mrr.id = mrs.meeting_relay_result_id
            JOIN meeting_programs mp ON mp.id = mrr.meeting_program_id
            JOIN meeting_events me ON me.id = mp.meeting_event_id
            JOIN event_types et ON et.id = me.event_type_id
          WHERE mrs.swimmer_id = #{swimmer_id}
          GROUP BY mrs.swimmer_id, mrs.badge_id
        ) AS sbr ON sbr.badge_id = sbs.badge_id
        -- Current team and category
        LEFT JOIN (
          SELECT b.id AS badge_id,
            CONCAT(t.editable_name, ':', t.id) AS current_team,
          ct.code AS current_category
          FROM badges b
          JOIN seasons s ON s.id = b.season_id
          JOIN category_types ct ON ct.id = b.category_type_id
          JOIN teams t ON t.id = b.team_id
          WHERE b.swimmer_id = #{swimmer_id}
            AND s.end_date > curdate()
        ) AS crb ON crb.badge_id = sbs.badge_id
        WHERE sbs.swimmer_id = #{swimmer_id}
        GROUP BY sbs.swimmer_id;
      SQL
    end
  end
end
