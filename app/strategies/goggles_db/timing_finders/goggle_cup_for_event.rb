# frozen_string_literal: true

module GogglesDb
  module TimingFinders
    #
    # = GoggleCupForEvent strategy object
    #
    #   - file vers.: 1.58
    #   - author....: Steve A.
    #   - build.....: 20210106
    #
    class GoggleCupForEvent < BaseStrategy
      # Given a current GoggleCup definition exists (and the swimmer is enrolled in it with any Badge),
      # this returns an empty MIR filled with the "standard time" associated with the specified event entry.
      #
      # == Returns:
      #
      # A MeetingIndividualResult row (never +nil+) encapsulating the Timing instance associated with (in FIFO priority):
      #
      # 1) The GoggleCup standard or minimal entry time for the corresponding event;
      #
      #    not found? => 2) The last MIR achieved by the swimmer on any event of the same type, in any meeting.
      #
      def search_by(swimmer, meeting, event_type, pool_type)
        # TODO: retrieve GoggleCup standard timing, if GoggleCup exists (return if nil)
        # result = super(swimmer, meeting, event_type, pool_type) ...
        # result = GogglesDb::MeetingIndividualResult.new
        # return nil unless result.exists?
        # result.from_timing(Timing.new( ...GoggleCup standard timing values... ))

        result = nil # TODO: (GoggleCup still WIP for this version)
        return LastMirForEvent.new.search_by(swimmer, meeting, event_type, pool_type) unless result.present?

        result
      end
    end
  end
end
