# frozen_string_literal: true

require 'goggles_db'

namespace :normalize do
  desc 'Normalizes existing reservation data'
  task reservations: :environment do
    puts "\r\n*** Meeting reservation normalization ***"
    puts "\r\n--> Normalizing master reservations..."
    normalize_master_reservations
    puts "\r\nDone."
  end
  #-- -------------------------------------------------------------------------
  #++

  # Scans the master reservation table for existing duplicates (same badge + meeting on
  # different rows) and deletes only the duplicate rows that do not have associated deteails
  # (both for events & relays).
  def normalize_master_reservations
    updated_rows = 0
    # ANSI color codes: 31m = red; 32m = green; 33m = yellow; 34m = blue; 37m = white

    duplicate_keys = GogglesDb::MeetingReservation.group(:meeting_id, :badge_id).count.select { |_ids, dup_count| dup_count > 1 }.keys
    puts "\r\nDuplicates found: #{duplicate_keys.size}"

    # Collect all rows IDs involved:
    ids_to_be_checked = collect_meeting_reservation_ids_for(duplicate_keys)

    ids_to_be_checked.each do |id|
      row = GogglesDb::MeetingReservation.find_by_id(id)
      if row.meeting_event_reservations.count.zero? && row.meeting_relay_reservations.count.zero?
        row.destroy!
        updated_rows += 1
        $stdout.write("\033[1;33;31m×\033[0m")
      else
        $stdout.write("\033[1;33;32m.\033[0m")
      end
    end

    puts "\r\nTotal row updates: #{updated_rows} (should be >= #{duplicate_keys.size})"
  end
  #-- -------------------------------------------------------------------------
  #++

  # Collects a list of MeetingReservation IDs for all the given (meeting_id, badge_id)
  # tuples.
  def collect_meeting_reservation_ids_for(meeting_id_badge_id_tuple_list)
    meeting_id_badge_id_tuple_list.map do |id_pair|
      GogglesDb::MeetingReservation.where(meeting_id: id_pair.first, badge_id: id_pair.second).select(:id).map(&:id)
    end.flatten
  end
end
