# frozen_string_literal: true

namespace :db do
  namespace :check do
    desc <<~DESC
        Checks for missing TeamAffiliations & Badges from Badges & MIRs for a given Season ID.
      Assumes swimmer_id, team_id and season_id are "gold" in target tables.
      Returns the total number of issues found per type (missing or misplaced).

      Options: [Rails.env=#{Rails.env}]
               [season=<season_id>]
               [verbose=1|<0>]

    DESC
    task tas: :environment do |_t|
      puts "\r\n*** Task: Check TAs & Badges ***"
      season_id = ENV.include?('season') ? ENV['season'].to_i : 0
      verbose = ENV.include?('verbose') ? ENV['verbose'].to_i.positive? : false
      puts "--> Season ID: #{season_id}"
      unless season_id.positive? && GogglesDb::Season.exists?(id: season_id)
        puts '    Invalid season!'
        exit
      end
      puts '    VERBOSE=ON' if verbose
      puts

      # Missing TAs from badges:
      sql = <<-SQL.squish
        SELECT DISTINCT b.team_id team_id, t.editable_name name, #{season_id} season_id, NOW() created_at, NOW() updated_at
        FROM badges b INNER JOIN teams t ON t.id = b.team_id
        WHERE b.season_id = #{season_id} AND
              NOT EXISTS (select * from team_affiliations ta where ta.season_id = #{season_id} and ta.team_id = b.team_id);
      SQL
      execute_query_and_report(sql, 'TAs MISSING from Badges...', verbose)

      # Missing Badges from MIRs:
      sql = <<-SQL.squish
        SELECT DISTINCT mir.swimmer_id swimmer_id, mir.team_id team_id, #{season_id} season_id, mp.category_type_id category_type_id,
          5 entry_time_type_id,
          (select id from team_affiliations ta where ta.team_id = mir.team_id and ta.season_id = #{season_id}) team_affiliation_id,
          NOW() created_at, NOW() updated_at
        FROM meeting_individual_results mir
            INNER JOIN swimmers s ON (mir.swimmer_id = s.id)
            INNER JOIN meeting_programs mp ON (mir.meeting_program_id = mp.id)
            INNER JOIN meeting_events me ON (mp.meeting_event_id = me.id)
            INNER JOIN meeting_sessions ms ON (me.meeting_session_id = ms.id)
            INNER JOIN meetings m ON (ms.meeting_id = m.id)
        WHERE m.season_id = #{season_id} AND
              NOT EXISTS (select * from badges b where b.season_id = #{season_id} and b.team_id = mir.team_id and b.swimmer_id = mir.swimmer_id);
      SQL
      execute_query_and_report(sql, 'Badges MISSING in MIRs....', verbose)

      # Missing TAs from MIRs:
      sql = <<-SQL.squish
        SELECT DISTINCT mir.team_id team_id, t.editable_name name, #{season_id} season_id, NOW() created_at, NOW() updated_at
        FROM meeting_individual_results mir
          INNER JOIN teams t ON (mir.team_id = t.id)
          INNER JOIN meeting_programs mp ON (mir.meeting_program_id = mp.id)
          INNER JOIN meeting_events me ON (mp.meeting_event_id = me.id)
          INNER JOIN meeting_sessions ms ON (me.meeting_session_id = ms.id)
          INNER JOIN meetings m ON (ms.meeting_id = m.id)
        WHERE m.season_id = #{season_id} AND
          NOT EXISTS (select * from team_affiliations ta where ta.season_id = #{season_id} and ta.team_id = mir.team_id);
      SQL
      execute_query_and_report(sql, 'TAs MISSING from MIRs.....', verbose)

      # Misplaced TAs in MIRs (by comparing swimmer, team & season):
      sql = <<-SQL.squish
        SELECT mir.id, mir.team_id, mir.swimmer_id, mir.team_affiliation_id, ta2.id, ta2.team_id
        FROM meeting_individual_results mir
          INNER JOIN meeting_programs mp ON (mir.meeting_program_id = mp.id)
          INNER JOIN meeting_events me ON (mp.meeting_event_id = me.id)
          INNER JOIN meeting_sessions ms ON (me.meeting_session_id = ms.id)
          INNER JOIN meetings m ON (ms.meeting_id = m.id)
          INNER JOIN team_affiliations ta2 ON (mir.team_id = ta2.team_id and ta2.season_id = #{season_id})
          WHERE (m.season_id = #{season_id}) AND
                (mir.team_affiliation_id != (select id from team_affiliations ta where ta.team_id = mir.team_id and ta.season_id = #{season_id}));
      SQL
      execute_query_and_report(sql, 'TAs misplaced in MIRs....', verbose)
    end
    #-- -----------------------------------------------------------------------
    #++

    # Assuming <tt>sql</tt> is a valid SQL query statement, this will execute it and report
    # the output to the console. The string <tt>title</tt> is just for display purposes.
    def execute_query_and_report(sql, title, verbose)
      result = ActiveRecord::Base.connection.exec_query(sql)
      puts "- #{title}: #{result.rows.count}"
      print_formatted_result_set(result, verbose)
    end

    # Assuming <tt>result</tt> responds to :columns & :rows returning respectively an array of
    # string column names and an array of row (array) values, this will format the result as
    # as text table.
    def print_formatted_result_set(result, verbose)
      return if !verbose || result.rows.count.zero?

      puts "  First 10 rows:\r\n" if result.rows.count > 10
      puts result.columns.map { |name| format('%20s', name) }.join(' |')
      puts result.rows[0..9].map { |row| row.map { |value| format('%20s', value) }.join(' |') }.join("\r\n")
      puts "\r\n"
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
