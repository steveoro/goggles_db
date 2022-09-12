# frozen_string_literal: true

require 'goggles_db'

namespace :normalize do
  desc <<~DESC
      Normalizes all coded names (Meeting#code & SwimmingPool#nick_name) using the Normalizer helpers.
      For Meetings, this will try to detect & update also the edition using the normalizer.

    Options: [simulate=1|<0>]
             [limit=N|<0>]

      - simulate: when positive, the task will only output the prospected changes without actually
                  saving or changing the database at all.
                  (Useful to check the result before corrupting any data)

      - limit: when positive, only the first N rows will be processed (default 0: all rows)

  DESC
  task coded_names: :environment do
    simulate = ENV.include?('simulate') ? ENV['simulate'].to_i.positive? : false
    limit_rows = ENV.include?('limit') ? ENV['limit'].to_i : 0
    puts "\r\n*** Normalize coded names (and editions) ***"
    puts '==> SIMULATE MODE ON' if simulate

    puts "\r\n==> Processing Meetings (tot. #{GogglesDb::Meeting.count})"
    domain = limit_rows.positive? ? GogglesDb::Meeting.limit(limit_rows) : GogglesDb::Meeting.all
    domain.includes(meeting_sessions: { swimming_pool: %i[city pool_type] }).each do |meeting|
      city = meeting.swimming_pools&.first&.city&.name
      std_code = GogglesDb::Normalizers::CodedName.for_meeting(meeting.description, city)
      edition, _name_no_edition, edition_type_id = GogglesDb::Normalizers::CodedName.edition_split_from(meeting.description)
      # Ignore peculiar case:
      edition = meeting.edition if meeting.description.starts_with?(/#{edition} giorn+/i) # Ignore "NN Giorn(i|ate)" which isn't an edition number

      # Check if edition_type should be fixed for certain Federation Championships (which have recurring meetings only from year to year):
      if [GogglesDb::FederationType::FIN_ID, GogglesDb::FederationType::LEN_ID,
          GogglesDb::FederationType::FINA_ID].include?(meeting.federation_type.id) &&
         meeting.edition_type_id != edition_type_id &&
         meeting.edition_type_id == GogglesDb::EditionType::NONE_ID
        $stdout.write("\033[1;33;34m*\033[0m")
        puts " ID #{meeting.id}, edition_type: #{meeting.edition_type_id} => #{edition_type_id}"
        meeting.update!(edition_type_id: edition_type_id) unless simulate
      end

      # Check if edition number should be fixed:
      if edition != meeting.edition && edition.positive?
        $stdout.write("\033[1;33;34m*\033[0m")
        puts " ID #{meeting.id}, edition: #{meeting.edition} => #{edition} (#{meeting.description} " \
             "- #{meeting.edition_type.code})"
        meeting.update!(edition: edition) unless simulate
      end
      next unless std_code != meeting.code

      # Update the code:
      $stdout.write("\033[1;33;34m*\033[0m")
      puts " ID #{meeting.id}, code: #{meeting.code} => #{std_code}"
      meeting.update!(code: std_code) unless simulate
    end

    puts "\r\n\r\n==> Processing Swimming pools (tot. #{GogglesDb::SwimmingPool.count})"
    duplicated_code_ids = []
    domain = limit_rows.positive? ? GogglesDb::SwimmingPool.limit(limit_rows) : GogglesDb::SwimmingPool.all
    domain.includes(%i[city pool_type]).each do |swimming_pool|
      city = swimming_pool&.city&.name
      std_code = GogglesDb::Normalizers::CodedName.for_pool(swimming_pool.name, city, swimming_pool.pool_type.code)
      next unless std_code != swimming_pool.nick_name

      if GogglesDb::SwimmingPool.exists?(nick_name: std_code)
        $stdout.write("\033[1;33;31m!\033[0m")
        duplicated_code_ids << swimming_pool.id
      else
        $stdout.write("\033[1;33;34m*\033[0m")
        swimming_pool.update!(nick_name: std_code) unless simulate
      end
      puts " ID #{swimming_pool.id}, nick_name: #{swimming_pool.nick_name} => #{std_code}"

      # == MANUAL FIX in case of duplicates:
      # > pool = GogglesDb::SwimmingPool.find(<duplicate_id>)
      # > GogglesDb::SwimmingPool.where(city_id: pool.city_id).count
      #
      # Check which sessions are pointing to the latter and fix them using the best or most
      # up-to-date row (usually there are 2, same pool type):
      #
      # > ap GogglesDb::SwimmingPool.where(city_id: pool.city_id).first
      # > ap GogglesDb::SwimmingPool.where(city_id: pool.city_id).last
      #
      # Choose one, do the update and then delete the duplicate:
      #
      # > GogglesDb::MeetingSession.where(swimming_pool_id: <duplicate_id>).update_all(swimming_pool_id: <ok_id>)
      # > GogglesDb::SwimmingPool.delete(<duplicate_id>)
    end
    puts("\r\nWARNING: found already existing coded names in SwimmingPool IDs #{duplicated_code_ids.inspect}") if duplicated_code_ids.present?
    puts "\r\nDone."
  end
  #-- -------------------------------------------------------------------------
  #++
end
