# frozen_string_literal: true

require 'simple_command'
require_relative '../../strategies/goggles_db/timing_finders/factory'

module GogglesDb
  #
  # = MeetingEntry suggested timing finder command
  #
  #   - file vers.: 7.059
  #   - author....: Steve A.
  #   - build.....: 20210107
  #
  # Finds the best MeetingIndividualResult candidate (MIR, for brevity) that encapsulates
  # the timing to be used for a new MeetingEntry.
  #
  # The Meeting header is the only meeting detail that actually needs to be defined for this to work,
  # since typically the entry timing is needed *before* the official Meeting manifest posting.
  #
  class CmdFindEntryTime
    prepend SimpleCommand

    attr_reader :mir

    # Creates a new command object given the parameters.
    # Defaults to GogglesDb::EntryTimeType.last_race when the entry_time_type is not set on the Badge.
    def initialize(swimmer, meeting, event_type, pool_type, entry_time_type = GogglesDb::EntryTimeType.last_race)
      @swimmer = swimmer
      @meeting = meeting
      @event_type = event_type
      @pool_type = pool_type
      @entry_time_type = entry_time_type
    end

    # Sets:
    # - #result: the timing of the latest/best MIR of the same event, for the same swimmer, depending on EntryTimeType value.
    #            `0'00"00` in case of no result ("no time").
    # - #mir:    the actual MeetingIndividualResult associated with the #result timing.
    #            A new, empty MIR in case of no result ("no time"); it is never +nil+.
    #
    # Always returns itself. Check #success? or #errors.empty? for detecting outcome.
    #
    def call
      return unless internal_members_valid?

      @mir = TimingFinders::Factory.for(@entry_time_type)
                                   .search_by(@swimmer, @meeting, @event_type, @pool_type)
      @mir.to_timing
    end
    #-- --------------------------------------------------------------------------
    #++

    private

    # Checks validity of the constructor parameters; returns +false+ in case of error.
    def internal_members_valid?
      # (The Meeting instance is not critical and could also be nil is some edge use-cases)
      return true if @swimmer.instance_of?(GogglesDb::Swimmer) &&
                     @event_type.instance_of?(GogglesDb::EventType) &&
                     @pool_type.instance_of?(GogglesDb::PoolType) &&
                     @entry_time_type.instance_of?(GogglesDb::EntryTimeType)

      errors.add(:msg, 'Invalid constructor parameters')
      false
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
