# frozen_string_literal: true

require 'goggles_db'
require 'benchmark'

namespace :normalize do
  desc ''
  desc <<~DESC
      Normalizes & recomputes the timing from start & length columns for MRS rows where
    these have been found nil due to structural changes.

    In previous Goggles versions the "timing from start" columns where the ones
    currently used for deltas and MRS didn't have a length_from_start column at all.

    So, in order to normalize existing data with current column meaning and usage,
    all relay timings with these columns found nil need to be changed as following:

    - timing columns    => contained absolute timing => move the value to new columns ("from start")
    - timing found zero => left as they are (they do exist)
    - delta timings     => recomputed from existing legacy values
    - length in meters  => computed using relay phase order and overall length

    Options: [newer_than=N]

      - newer_than: specify a number of days for filtering data by 'updated_at'
                    (rows will be updated_at > 'newer_than'.days.ago);
                    default: NO FILTERING, ALL ROWS will be processed

  DESC
  task relay_laps: :environment do
    puts("\r\n*** MRS & RelayLap length & timings from start reconstruction ***")
    newer_than = ENV.include?('newer_than') ? ENV['newer_than'].to_i.days.ago : nil
    puts("- Filter: 'updated_at > #{newer_than}'") if newer_than
    timing = Benchmark.measure { fix_nil_columns(newer_than) }

    puts("\r\n- Benchmark timings:")
    puts('                     user     system      total        real')
    puts("Fixing MRS:  #{timing}")
    puts("\r\nDone.")
  end
  #-- -------------------------------------------------------------------------
  #++

  private

  # Loops on all MRS rows that have a nil length and timing and tries to reconstruct/fix the proper
  # values given its sibling rows (MRR + MRS + RL).
  #
  # == Params:
  # - newer_than: time filter for updated_at; no filtering for +nil+
  #
  def fix_nil_columns(newer_than) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    # domain = GogglesDb::MeetingRelaySwimmer.where(minutes_from_start: nil, seconds_from_start: nil, hundredths_from_start: nil, length_in_meters: nil)
    domain = GogglesDb::MeetingRelayResult.includes(:meeting_relay_swimmers)
                                          .joins(:meeting_relay_swimmers)
                                          .where(
                                            'meeting_relay_swimmers.minutes_from_start': nil,
                                            'meeting_relay_swimmers.seconds_from_start': nil,
                                            'meeting_relay_swimmers.hundredths_from_start': nil,
                                            'meeting_relay_swimmers.length_in_meters': nil
                                          ).distinct
    domain = domain.where('updated_at > ?', newer_than) if newer_than
    total_rows = domain.count
    i = 0
    puts("\r\n--> Found #{total_rows} MRR parent result rows having sibling MRS with nil timing from start & length columns.")
    # puts("    (1x'\033[1;33;32m.\033[0m' => 10 rows) Processing...") if total_rows.positive?
    puts('    Processing...') if total_rows.positive?
    domain.find_each do |mrr|
      $stdout.write("\033[1;33;32m.\033[0m") # Bold green for external loop

      previous_timing = Timing.new
      # A delta timing can be computed if the difference is greater or equal to this value:
      delta_tolerance = Timing.new(hundredths: 0, seconds: 22, minutes: 0)

      mrr.meeting_relay_swimmers.order(:relay_order).find_each do |mrs|
        i += 1
        mrs.length_in_meters = mrs.relay_order * mrs.parent_result.phase_length_in_meters
        legacy_timing = mrs.to_timing

        # Move existing timing into proper destination columns & recompute delta:
        if legacy_timing.positive? && mrs.to_timing(from_start: true).zero?
          # Compute_deltas:
          # Difference with previous timing is too short to be considered "from start"?
          # => ASSUME legacy_timing is already a delta
          # => compute ABS "from start" summing delta to previous
          if (legacy_timing - previous_timing) < delta_tolerance
            $stdout.write("\033[0;33;36m+\033[0m")
            mrs.from_timing(legacy_timing + previous_timing, from_start: true) # Set "from_start" fields
          else # Difference seems to be a proper delta:
            $stdout.write("\033[0;33;36mΔ\033[0m")
            mrs.from_timing(legacy_timing, from_start: true) # Set "from_start" fields
            mrs.from_timing(legacy_timing - previous_timing) # Compute Delta
          end
          previous_timing = mrs.to_timing(from_start: true)

        elsif mrs.to_timing(from_start: true).zero? # (converted from nils)
          $stdout.write("\033[0;33;36m0\033[0m") # Signal we're setting zeroes
          mrs.from_timing(Timing.new, from_start: true) # Clear from_start fields (that are nil)

        else
          # (NOTE: this should never happen)
          $stdout.write("\033[0;33;36m=\033[0m") # Signal we're leaving "as is"
        end

        mrs.save!
      end
    end

    puts("\r\nUpdated #{i} MRS rows.") if i.positive?
    nil_count = GogglesDb::MeetingRelaySwimmer.where(minutes_from_start: nil, seconds_from_start: nil, hundredths_from_start: nil).count
    puts("Remaining #{nil_count} MRS rows with nil timing from start values.") if nil_count.positive?
  end
  #-- -------------------------------------------------------------------------
  #++
end
