# frozen_string_literal: true

module GogglesDb
  module TimingFinders
    #
    # = BestMIRForEvent strategy object
    #
    #   - version:  7-0.1.91
    #   - author:   Steve A.
    #   - build:    20210330
    #
    class BestMIRForEvent < BaseStrategy
      # Finds the absolute personal-best's MeetingIndividualResult instance associated with
      # the specified event and pool type.
      #
      # The result will be independent from the actual setting of the 'personal_best' flag column
      # on the MIR row (uses the sorting order by timing on the scoped result).
      #
      # === Returns:
      #
      # The MeetingIndividualResult row (never +nil+) that stores the timing for (in FIFO priority):
      #
      # 1) The swimmer's best result for the same event type in any attended meeting;
      #
      #    not found? => 2) No-time (a new, empty MIR).
      #
      # === Note on 'personal_best' flag column:
      # @legacy
      #
      # Usually, personal-best timings for each Swimmer are discriminated directly on each MIR row by
      # the specific `personal_best` flag column, which is periodically set/reset by an automated procedure.
      #
      # This procedure lives on a dedicated rake task (Admin app) that, in turn, needs to be run at least after each
      # Meeting results acquisition (typically, at the end of each the data-import procedure run).
      #
      # This method purposely doesn't check this flag and can be used even in between data-import
      # cycles.
      #
      def search_by(swimmer, meeting, event_type, pool_type)
        result = super(swimmer, meeting, event_type, pool_type)
        return NoTimeForEvent.new.search_by(swimmer, meeting, event_type, pool_type) if result.blank?

        result.by_timing(:asc).first
      end
    end
  end
end
