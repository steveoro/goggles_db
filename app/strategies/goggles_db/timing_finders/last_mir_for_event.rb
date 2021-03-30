# frozen_string_literal: true

module GogglesDb
  module TimingFinders
    #
    # = GoggleCupForEvent strategy object
    #
    #   - file vers.: 0.1.91
    #   - author....: Steve A.
    #   - build.....: 20210330
    #
    class LastMIRForEvent < BaseStrategy
      # Finds the generic, last MeetingIndividualResult row for the specified event and pool type.
      #
      # == Returns:
      #
      # The MeetingIndividualResult row (never +nil+) that stores the timing for (in FIFO priority):
      #
      # 1) The swimmer's *last* result for the same event type in any attended meeting;
      #
      #    not found? => 2) No-time (a new, empty MIR).
      #
      def search_by(swimmer, meeting, event_type, pool_type)
        result = super(swimmer, meeting, event_type, pool_type)
        return NoTimeForEvent.new.search_by(swimmer, meeting, event_type, pool_type) unless result.present?

        result.by_date(:desc).first
      end
    end
  end
end
