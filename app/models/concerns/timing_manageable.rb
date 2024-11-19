# frozen_string_literal: true

require 'active_support'

#
# = TimingManageable
#
#   - version:  7-0.7.24
#   - author:   Steve A.
#
# Concrete Interface for Timing helper methods (@see lib/wrappers/timing.rb).
# By including this concern, the includee adds to itself the #to_timing and
# the #from_timing methods.
#
# Assumes to be included into an ActiveRecord::Base sibling that includes the following fields:
# - <tt>:hundredths</tt> => Integer value for hundredths of a second.
# - <tt>:seconds</tt> => Integer value for seconds.
# - <tt>:minutes</tt> => Integer value for minutes.
#
# Note that, currently, this concern does not use and ignores the <tt>:hours</tt> & <tt>:days</tt>
# fields from the includee.
#
module TimingManageable
  extend ActiveSupport::Concern

  # [Steve A.] Can't enforce checking respond_to? in includees here, because since ver.7 this
  # concern is included in a shared abstract class (can't be instantiated).

  # [Steve A.] Please leave this here as future reference:
  # ---8<---
  # This will raise an exception if the includee does not already have defined the required fields:
  # def self.included(model)
  #   base_instance = model.new
  #   unless base_instance.respond_to?(:hundredths) &&
  #          base_instance.respond_to?(:seconds) &&
  #          base_instance.respond_to?(:minutes)
  #     raise ArgumentError, "Includee #{model} must have the attributes #hundredths, #seconds & #minutes."
  #   end
  # end
  # ---8<---
  #-- ------------------------------------------------------------------------
  #++

  # Returns +true+ if the timing associated with this result is positive.
  # If the includee responds (at least) also to #hundredths_from_start,
  # this will check all the <tt>XXX_from_start</tt> columns as well.
  def positive?
    base_timing_positive = minutes.positive? || seconds.positive? || hundredths.positive?
    return base_timing_positive unless respond_to?(:hundredths_from_start)

    base_timing_positive || minutes_from_start.positive? || seconds_from_start.positive? || hundredths_from_start.positive?
  end

  # Returns +true+ if the timing associated with this result is zero.
  # If the includee responds (at least) also to #hundredths_from_start,
  # this will check all the <tt>XXX_from_start</tt> columns as well.
  def zero?
    !positive?
  end
  #-- ------------------------------------------------------------------------
  #++

  # Returns a new Timing instance initialized with the timing data from this row
  # (@see lib/wrappers/timing.rb)
  #
  # == Params:
  # - <tt>from_start</tt>: when true, the resulting Timing instance will be
  #   created using the <tt>XXX_from_start</tt> attributes instead of
  #   the default ones.
  #
  def to_timing(from_start: false)
    # Note that:
    # - MIR, Lap, etc don't hold an "hour" column due to the typical short time span of the competition)
    # - Always return timing based on legacy columns unless specified by params & supported too
    unless from_start && respond_to?(:hundredths_from_start)
      # Return timing based on delta columns:
      return Timing.new(
        hundredths: hundredths.to_i,
        seconds: seconds.to_i,
        minutes: minutes.to_i % 60,
        hours: 60 * (minutes.to_i / 60),
        days: 0
      )
    end

    # Return timing based on "absolute" columns:
    Timing.new(
      hundredths: hundredths_from_start.to_i,
      seconds: seconds_from_start.to_i,
      minutes: minutes_from_start.to_i % 60,
      hours: 60 * (minutes_from_start.to_i / 60),
      days: 0
    )
  end

  # Sets the internal #hundredths, #seconds & #minutes members according to the specified Timing value.
  # Supports even hours & days(@see lib/wrappers/timing.rb).
  # Works also for the #XXX_from_start sibling members (without the hours or days resolution)
  #
  # == Params:
  # - <tt>timing</tt>: a Timing instance holding the values to be set into the
  #   destination members.
  #
  # - <tt>from_start</tt>: when +true+, the destination members will be
  #   the <tt>XXX_from_start</tt> attributes instead of the default ones.
  #
  def from_timing(timing, from_start: false) # rubocop:disable Metrics/AbcSize
    if from_start && respond_to?(:hundredths_from_start)
      self.hundredths_from_start = timing.hundredths.to_i
      self.seconds_from_start = timing.seconds.to_i
      self.minutes_from_start = timing.minutes.to_i
      # Currently unused:
      self.hours_from_start = timing.hours.to_i if respond_to?(:hours_from_start=)
      self.days_from_start = timing.days.to_i if respond_to?(:days_from_start=)
    else
      self.hundredths = timing.hundredths.to_i
      self.seconds = timing.seconds.to_i
      self.minutes = timing.minutes.to_i
      self.hours = timing.hours.to_i if respond_to?(:hours=)
      self.days = timing.days.to_i if respond_to?(:days=)
    end

    self
  end
  #-- ------------------------------------------------------------------------
  #++
end
