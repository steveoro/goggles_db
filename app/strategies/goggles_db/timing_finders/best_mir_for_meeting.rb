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
    class BestMIRForMeeting < BaseStrategy
      # Finds the "relative best" MeetingIndividualResult row for the specified event, pool type
      # and inside a restricted subset of Meetings, which should all beloging to the same edition type.
      #
      # == Returns:
      #
      # The MeetingIndividualResult row (never +nil+) that stores the timing for (in FIFO priority):
      #
      # 1) The swimmer's best result for the same event type & meeting;
      #    (Meetings must have the same code to be recognized as different editions of the same Meeting)
      #
      #    not found? => 2) The GoggleCup standard or minimal entry time for the corresponding event;
      #
      def search_by(swimmer, meeting, event_type, pool_type)
        result = super(swimmer, meeting, event_type, pool_type).for_meeting_code(meeting)
        return GoggleCupForEvent.new.search_by(swimmer, meeting, event_type, pool_type) if result.blank?

        result.by_timing(:asc).first
      end
    end
  end
end
