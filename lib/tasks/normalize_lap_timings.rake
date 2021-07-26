# frozen_string_literal: true

require 'goggles_db'

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
namespace :normalize do
  desc 'Normalizes laps timings'
  task laps: :environment do
    puts "\r\n*** Laps normalization ***"
    puts "\r\n--> Scanning all MIRs with Laps..."
    scan_mirs_with_laps
    puts "\r\n--> Scanning all UserResults with Laps..."
    scan_user_results_with_laps
    puts "\r\nDone."
  end
  #-- -------------------------------------------------------------------------
  #++

  # Scans all MIRs with laps, lap by lap, searching for:
  #
  # 0. missing parent result association
  # 1. computable & empty "delta"s (diff timings)
  # 2. computable & empty "from_start"s (absolute timings)
  # 3. "delta" == "from_start" when there's a preceding lap timing at a different resolution (length in meters)
  #
  # If the timing can be corrected, the lap row will be updated.
  def scan_mirs_with_laps
    updated_rows = 0
    orphan_found = false
    # ANSI color codes: 31m = red; 32m = green; 33m = yellow; 34m = blue; 37m = white

    mir_count = GogglesDb::Lap.select(:meeting_individual_result_id).distinct.count
    puts "#{mir_count} MIRs with laps found. Processing lap groups one by one:"
    GogglesDb::Lap.select(:meeting_individual_result_id)
                  .distinct
                  .map(&:meeting_individual_result).each do |mir|
      # 0. RED: Lap associated to a missing MIR?
      unless mir.present?
        # (This will happen when a Lap is linked to a MIR that doesn't exist anymore - FK is currently missing)
        orphan_found = true
        $stdout.write("\033[1;33;31mx\033[0m")
        next
      end

      mir_laps = mir.laps.by_distance.to_a
      mir_laps.each_with_index do |lap, lap_idx|
        cond = detect_case_condition(lap, lap_idx)

        case cond
        when 1
          # 1. WHITE: Empty 'delta' and previous lap available or 'from_start' present?
          process_case1(mir_laps, lap, lap_idx)
          $stdout.write("\033[1;33;37m#{lap_idx + 1}\033[0m")
          updated_rows += 1
        when 2
          # 2. YELLOW: Empty 'from_start' and previous lap available or 'delta' present?
          process_case2(mir_laps, lap, lap_idx)
          $stdout.write("\033[1;33;33m#{lap_idx + 1}\033[0m")
          updated_rows += 1
        when 3
          # 3. BLUE: 'delta' == 'from_start' and previous lap available?
          process_case3(mir_laps, lap, lap_idx)
          updated_rows += 1
        end
        # (end lap loop)
      end
      # (end MIR loop)
      $stdout.write("\033[1;33;32m.\033[0m")
    end

    updated_rows = delete_orphan_rows!(updated_rows) if orphan_found
    puts "\r\nTotal row fixes: #{updated_rows}"
  end

  # Same as scan_mirs_with_laps: scans all UserResults with laps, lap by lap,
  # searching for:
  #
  # 0. missing parent result association
  # 1. computable & empty "delta"s (diff timings)
  # 2. computable & empty "from_start"s (absolute timings)
  # 3. "delta" == "from_start" when there's a preceding lap timing at a different resolution (length in meters)
  #
  # If the timing can be corrected, the lap row will be updated.
  def scan_user_results_with_laps
    updated_rows = 0
    # ANSI color codes: 31m = red; 32m = green; 33m = yellow; 34m = blue; 37m = white

    result_count = GogglesDb::UserLap.select(:user_result_id).distinct.count
    puts "#{result_count} UserResults with laps found. Processing lap groups one by one:"
    GogglesDb::UserLap.select(:user_result_id)
                      .distinct
                      .map(&:user_result).each do |result|
      # 0. RED: Lap associated to a missing parent? ('Shouldn't happen for UserLaps, since FKs are now in place)
      unless result.present?
        # NOTE: although this shouldn't happen anymore here, we'll keep the code to detect it in case
        # this shows up again when restoring old dumps.
        $stdout.write("\033[1;33;31mx\033[0m")
        next
      end

      laps_group = result.laps.by_distance.to_a
      laps_group.each_with_index do |lap, lap_idx|
        cond = detect_case_condition(lap, lap_idx)

        case cond
        when 1
          # 1. WHITE: Empty 'delta' and previous lap available or 'from_start' present?
          process_case1(laps_group, lap, lap_idx)
          $stdout.write("\033[1;33;37m#{lap_idx + 1}\033[0m")
          updated_rows += 1
        when 2
          # 2. YELLOW: Empty 'from_start' and previous lap available or 'delta' present?
          process_case2(laps_group, lap, lap_idx)
          $stdout.write("\033[1;33;33m#{lap_idx + 1}\033[0m")
          updated_rows += 1
        when 3
          # 3. BLUE: 'delta' == 'from_start' and previous lap available?
          process_case3(laps_group, lap, lap_idx)
          updated_rows += 1
        end
        # (end lap loop)
      end
      # (end Result loop)
      $stdout.write("\033[1;33;32m.\033[0m")
    end
    puts "\r\nTotal row fixes: #{updated_rows}"
  end
  #-- -------------------------------------------------------------------------
  #++

  private

  # Checks: delta timing missing && (abs timing present || prev. lap exists)
  #
  # == Params:
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps group associated to the current MIR
  #
  # == Returns:
  # true if the condition applies, false otherwise
  #
  def case_delta_zero_and_abs_present(lap, lap_idx)
    lap.hundredths.to_i.zero? && lap.seconds.to_i.zero? && lap.minutes.to_i.zero? &&
      (lap.hundredths_from_start.present? && lap.seconds_from_start.present? &&
      lap.minutes_from_start.present? || lap_idx.positive?)
  end

  # Checks: abs timing missing && (delta timing present || prev. lap exists)
  #
  # == Params:
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps group associated to the current MIR
  #
  # == Returns:
  # true if the condition applies, false otherwise
  #
  def case_abs_zero_and_delta_present(lap, lap_idx)
    lap.hundredths_from_start.to_i.zero? && lap.seconds_from_start.to_i.zero? &&
      lap.minutes_from_start.to_i.zero? &&
      (lap.hundredths.present? && lap.seconds.present? && lap.minutes.present? || lap_idx.positive?)
  end

  # Checks: (abs timing == delta timing) && prev. lap exists
  #
  # == Params:
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps group associated to the current MIR
  #
  # == Returns:
  # true if the condition applies, false otherwise
  #
  def case_abs_eq_delta(lap, lap_idx)
    lap.hundredths == lap.hundredths_from_start && lap.seconds == lap.seconds_from_start &&
      lap.minutes == lap.minutes_from_start && lap_idx.positive?
  end

  # Detects which conditional case applies to the current lap, given also its positional index.
  #
  # == Params:
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps group associated to the current MIR
  #
  # == Returns:
  # The conditional case number, 1..3, that applies to the current lap; 0 if everything is ok
  # and the lap timings do not need any fixing.
  #
  def detect_case_condition(lap, lap_idx)
    return 1 if case_delta_zero_and_abs_present(lap, lap_idx)
    return 2 if case_abs_zero_and_delta_present(lap, lap_idx)
    return 3 if case_abs_eq_delta(lap, lap_idx)

    0 # (case: ok, skip)
  end

  # Process fix case #1 (WHITE colored).
  # Empty 'delta' AND (previous lap available OR 'from_start' (abs timing) present)
  #
  # == Params:
  # - laps_group: array of Laps associated to the same MIR (currently being processed)
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps_group
  #
  # == Returns:
  # Unless an error is raised, returns true.
  #
  def process_case1(laps_group, lap, lap_idx)
    if lap.hundredths_from_start.present? && lap_idx.zero?
      # Use "from_start" timing as delta
      lap.hundredths = lap.hundredths_from_start
      lap.seconds = lap.seconds_from_start
      lap.minutes = lap.minutes_from_start
    else
      # Compute 'delta' using previous lap (which must be available in this case)
      prev_lap = laps_group[lap_idx - 1]
      # Compute difference from prev. lap (which must have been checked or fixed during previous iteration)
      # => curr.abs - prev.abs
      curr_abs = Timing.new(
        hundredths: lap.hundredths_from_start,
        seconds: lap.seconds_from_start,
        minutes: lap.minutes_from_start % 60, hours: 60 * (lap.minutes_from_start / 60)
      )
      prev_abs = Timing.new(
        hundredths: prev_lap.hundredths_from_start,
        seconds: prev_lap.seconds_from_start,
        minutes: prev_lap.minutes_from_start % 60, hours: 60 * (prev_lap.minutes_from_start / 60)
      )
      delta_diff = curr_abs - prev_abs
      lap.hundredths = delta_diff.hundredths
      lap.seconds = delta_diff.seconds
      lap.minutes = delta_diff.minutes
    end
    lap.save!
  end

  # Process fix case #2 (YELLOW colored).
  # Empty 'from_start' (abs timing) AND (previous lap available OR 'delta' present)
  #
  # == Params:
  # - laps_group: array of Laps associated to the same MIR (currently being processed)
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps_group
  #
  # == Returns:
  # Unless an error is raised, returns true.
  #
  def process_case2(laps_group, lap, lap_idx)
    if lap.hundredths.present? && lap_idx.zero?
      # Use delta timing as absolute
      lap.hundredths_from_start = lap.hundredths
      lap.seconds_from_start = lap.seconds
      lap.minutes_from_start = lap.minutes
    else
      # Compute 'from_start' (abs timing) using previous lap as base + this delta value
      prev_lap = laps_group[lap_idx - 1]
      # Sum current delta timing to prev. lap (which must have been checked or fixed during previous iteration)
      # => prev.abs + curr.delta
      prev_abs = Timing.new(
        hundredths: prev_lap.hundredths_from_start,
        seconds: prev_lap.seconds_from_start,
        minutes: prev_lap.minutes_from_start % 60, hours: 60 * (prev_lap.minutes_from_start / 60)
      )
      curr_abs = prev_abs + lap.to_timing
      lap.hundredths_from_start = curr_abs.hundredths
      lap.seconds_from_start = curr_abs.seconds
      lap.minutes_from_start = curr_abs.minutes
    end
    lap.save!
  end

  # Process fiMetrics/CyclomaticComplexityx case #3 (BLUE colored; d: delta, a: abs).
  # 'delta' == 'from_start' (abs timing) AND previous lap available
  #
  # == Params:
  # - laps_group: array of Laps associated to the same MIR (currently being processed)
  # - lap: the currently processed Lap instance
  # - lap_idx: index of the lap inside the laps_group
  #
  # == Returns:
  # Unless an error is raised, returns true.
  #
  def process_case3(laps_group, lap, lap_idx)
    # Compute from previous lap (which must be available in this case)
    # Possible approaches:
    #
    # A. Duplicated timing is an abs timing  => curr.abs - prev.delta (most common)
    # B. Duplicated timing is a delta timing => prev.abs + curr.delta
    #
    # To select which strategy, compute curr.delta - prev.abs first, and check if it could be an actual delta
    prev_lap = laps_group[lap_idx - 1]
    delta_tolerance = Timing.new(hundredths: 0, seconds: 15, minutes: 0)
    prev_abs = Timing.new(
      hundredths: prev_lap.hundredths_from_start,
      seconds: prev_lap.seconds_from_start,
      minutes: prev_lap.minutes_from_start % 60, hours: 60 * (prev_lap.minutes_from_start / 60)
    )
    delta_diff = lap.to_timing - prev_abs

    # Compute a possible range limit to reckon the type of value stored in the delta fields:
    prev_lap.seconds += 15
    if delta_diff <= delta_tolerance
      # => made a diff using an actual delta as ending range
      # => delta fields used are actually storing a "delta" timing
      # => case B: lap.abs = prev_lap.abs + lap.delta
      curr_abs = prev_abs + lap.to_timing
      lap.hundredths_from_start = curr_abs.hundredths
      lap.seconds_from_start = curr_abs.seconds
      lap.minutes_from_start = curr_abs.minutes
      $stdout.write("\033[1;33;34mΔ#{lap_idx + 1}\033[0m")
    else
      # => made a diff using an abs timing as ending range
      # => delta fields used are actually storing an "abs" timing
      # => case A: computed delta_diff is the correct delta => lap.delta = delta_diff
      lap.from_timing(delta_diff)
      $stdout.write("\033[1;33;34ma#{lap_idx + 1}\033[0m")
    end
    lap.save!
  end
  #-- -------------------------------------------------------------------------
  #++

  # Deletes any Lap row that is associated to a missing parent MIR.
  #
  # == Params:
  # - updated_rows: row updates count so far
  #
  # == Returns:
  # updated_rows new value
  #
  def delete_orphan_rows!(updated_rows)
    puts "\r\nOrphan laps were found: scanning for MIR IDs that do not have an existing MIR row anymore..."
    mir_ids = GogglesDb::Lap.select(:meeting_individual_result_id).distinct.map(&:meeting_individual_result_id)
    missing_ids = mir_ids.reject { |id| GogglesDb::MeetingIndividualResult.exists?(id) }
    orphan_rows = GogglesDb::Lap.where(meeting_individual_result_id: missing_ids)
    puts "Found #{missing_ids.count} association(s). Deleting #{orphan_rows.count} associated orphan rows..."
    updated_rows += orphan_rows.count
    orphan_rows.delete_all
    updated_rows
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
