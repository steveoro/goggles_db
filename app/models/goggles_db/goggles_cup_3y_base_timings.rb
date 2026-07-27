# frozen_string_literal: true

module GogglesDb
  # = GogglesCup3yBaseTimings (Scenic View model)
  #
  # Collects the best result for each swimmer/event/pool tuple across the
  # 3 championship years preceding the current ongoing championship year.
  # These timings serve as "base timings" for Goggles Cup ranking computations.
  #
  class GogglesCup3yBaseTimings < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = 'goggles_cup_3y_base_timings'
  end
end
