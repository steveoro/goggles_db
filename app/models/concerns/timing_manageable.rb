# frozen_string_literal: true

require 'active_support'

#
# = TimingManageable
#
#   - version:  7.070
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

  # This will raise an exception if the includee does not already have defined the required fields:
  def self.included(model)
    base_instance = model.new
    unless base_instance.respond_to?(:hundredths) &&
           base_instance.respond_to?(:seconds) &&
           base_instance.respond_to?(:minutes)
      raise ArgumentError, "Includee #{model} must have the attributes #hundredths, #seconds & #minutes."
    end
  end

  # Returns a new Timing instance initialized with the timing data from this row
  # (@see lib/wrappers/timing.rb)
  #
  def to_timing
    # MIR doesn't hold an "hour" column due to the typical short time span of the competition:
    Timing.new(hundredths, seconds, minutes % 60, 60 * (minutes / 60))
  end

  # Sets the internal #hundredths, #seconds & #minutes members according to the specified Timing value.
  # Supports even hours & days(@see lib/wrappers/timing.rb)
  #
  def from_timing(timing)
    self.hundredths = timing.hundredths
    self.seconds = timing.seconds
    self.minutes = timing.minutes
    self.hours = timing.hours if respond_to?(:hours=)
    self.days = timing.days if respond_to?(:days=)
    self
  end
  #-- ------------------------------------------------------------------------
  #++
end
