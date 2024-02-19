# frozen_string_literal: true

require 'goggles_db'
require 'benchmark'

namespace :normalize do
  desc ''
  desc <<~DESC
      Normalizes/recomputes counters caching columns for MRR, MRS & RelayLaps.

    Run this task after EACH data-import push that includes relays data in it.
    Rows will be updated and can be subsequently filtered out on the next data-import run.

    (Assumes this task won't be run more often than daily; safe to be run twice
     in any case)

    Options: [newer_than=N]

      - newer_than: specify a number of days for filtering data by 'updated_at'
                    (rows will be updated_at > 'newer_than'.days.ago);
                    default: NO FILTERING, ALL ROWS will be processed

  DESC
  task relay_counters: :environment do
    puts("\r\n*** MRR/MRS/RelayLap counters refresh/normalization ***")
    newer_than = ENV.include?('newer_than') ? ENV['newer_than'].to_i.days.ago : nil
    puts("- Filter: 'updated_at > #{newer_than}'") if newer_than
    timing1 = Benchmark.measure { reset_counters_for(GogglesDb::MeetingRelayResult, :meeting_relay_swimmers, newer_than) }
    timing2 = Benchmark.measure { reset_counters_for(GogglesDb::MeetingRelaySwimmer, :relay_laps, newer_than) }

    puts("\r\n- Benchmark timings:")
    puts('                     user     system      total        real')
    puts("Timing MRR->MRS: #{timing1}")
    puts("Timing MRS->RL : #{timing2}")
    puts("\r\nDone.")
  end
  #-- -------------------------------------------------------------------------
  #++

  private

  # Loops on all rows of the specified +klass+ updated after the specified date
  # and calls a reset_counters on each instance found.
  #
  # == Params:
  # - klass: model class to be processed
  # - counter_name: counter name symbol
  # - newer_than: time filter for updated_at; no filtering for +nil+
  #
  def reset_counters_for(klass, counter_name, newer_than)
    domain = newer_than ? klass.where('updated_at > ?', newer_than) : klass
    total_rows = domain.count
    i = 0
    puts("\r\n--> Found #{total_rows} #{klass.name} rows.")
    puts("    (1x'\033[1;33;32m.\033[0m' => 100 rows) Processing...") if total_rows.positive?
    domain.find_each do |row|
      i += 1
      $stdout.write("\033[1;33;32m.\033[0m") if (i % 100).zero?
      klass.reset_counters(row.id, counter_name, touch: true)
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
