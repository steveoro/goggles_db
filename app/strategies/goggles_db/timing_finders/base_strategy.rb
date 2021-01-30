# frozen_string_literal: true

module GogglesDb
  #
  # = TimingFinders module
  #
  # Wraps all finder strategies that can be plugged into CmdFindEntryTime by the
  # dedicated factory.
  #
  # The factory will choose & build which strategy has to be used by the command object
  # depending on the specified EntryTimeType.
  #
  module TimingFinders
    #
    # = BaseStrategy parent object
    #
    #   - file vers.: 1.58
    #   - author....: Steve A.
    #   - build.....: 20210106
    #
    # Encapsulates the base interface for its siblings.
    #
    class BaseStrategy
      # Base search method for this family of Strategies.
      # Returns a scoped MIR relation.
      #
      def search_by(swimmer, _meeting, event_type, pool_type)
        GogglesDb::MeetingIndividualResult.qualifications
                                          .for_swimmer(swimmer)
                                          .for_event_type(event_type)
                                          .for_pool_type(pool_type)
      end
    end
  end
end
