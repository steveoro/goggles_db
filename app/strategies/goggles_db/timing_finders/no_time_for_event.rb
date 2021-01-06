# frozen_string_literal: true

module GogglesDb
  module TimingFinders
    #
    # = NoTimeForEvent strategy object
    #
    #   - file vers.: 1.58
    #   - author....: Steve A.
    #   - build.....: 20210106
    #
    # Dummy strategy that returns an empty MIR (which corresponds to a zeroed
    # timing instance).
    #
    class NoTimeForEvent < BaseStrategy
      # Always returns a new, empty MIR.
      #
      def search_by(_swimmer, _meeting, _event_type, _pool_type)
        GogglesDb::MeetingIndividualResult.new
      end
    end
  end
end
