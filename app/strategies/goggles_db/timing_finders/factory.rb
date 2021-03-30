# frozen_string_literal: true

require 'singleton'

module GogglesDb
  module TimingFinders
    #
    # = TimingFinders singleton factory
    #
    #   - file vers.: 1.58
    #   - author....: Steve A.
    #   - build.....: 20210106
    #
    # Allows to create a plug-in strategy object for finding a valid timing
    # for any Meeting entry, according the specified parameters.
    #
    class Factory
      include Singleton

      # Returns a dedicated strategy instance depending on the specified EntryTimeType.
      #
      # The strategy allows to retrieve always a MIR instance that encapsulates the requested timing
      # for the corresponding meeting entry time according to the given entry time type
      # (which defines the kind of timing that has to be used for the new entry).
      #
      # It never returns +nil+.
      #
      # === EntryTimeTypes:
      #
      # - 'M': #manual?    => Manually chosen (nothing to do: typically, "no time").
      # - 'P': #personal?  => Personal best on same event, any meeting
      # - 'U': #last_race? => Last result on same event, any meeting
      # - 'G': #gogglecup? => GoggleCup standard time (current GoggleCup, if defined)
      # - 'A': #prec_year? => Best MIR among previous edition of the same meeting
      #
      # === Algorithm:
      #
      # Code/Type value priority, from bottom to top:
      #
      #  - prec_year? ("A") && MIR not found ? => use "G"
      #  - gogglecup? ("G") && MIR not found ? => use "U"
      #  - last_race? ("U") && MIR not found ? => use "P" => surely MIR doesn't exist => use "M"
      #  - personal? ("P") && MIR not found ? => use "M"
      #  - manual? ("M") ? => return "no time"
      #
      def self.for(entry_time_type)
        raise(ArgumentError, 'Invalid parameter specified') unless entry_time_type.instance_of?(GogglesDb::EntryTimeType)

        if entry_time_type.prec_year?
          BestMIRForMeeting.new

        elsif entry_time_type.gogglecup?
          GoggleCupForEvent.new

        elsif entry_time_type.last_race?
          LastMIRForEvent.new

        elsif entry_time_type.personal?
          BestMIRForEvent.new

        elsif entry_time_type.manual?
          NoTimeForEvent.new

        else
          raise(ArgumentError, 'New, unsupported or unimplemented EntryTimeType!')
        end
      end
    end
  end
end
