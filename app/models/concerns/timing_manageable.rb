# frozen_string_literal: true

require 'active_support'

#
# = TimingManageable
#
#   - version:  7.036
#   - author:   Steve A.
#
# Concrete Interface for Timing helper methods (@see lib/wrappers/timing.rb).
# By including this concern, the includee adds to itself the #to_timing method.
#
# Assumes to be included into an ActiveRecord::Base sibling that includes the following fields:
# - <tt>:hundreds</tt> => Integer value for hundreds of a second.
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
    unless base_instance.respond_to?(:hundreds) &&
           base_instance.respond_to?(:seconds) &&
           base_instance.respond_to?(:minutes)
      raise ArgumentError, "Includee #{model} must have the attributes #hundreds, #seconds & #minutes."
    end
  end

  # Returns a new Timing instance initialized with the timing data from this row
  # (@see lib/wrappers/timing.rb)
  #
  def to_timing
    # MIR doesn't hold an "hour" column due to the typical short time span of the competition:
    Timing.new(hundreds, seconds, minutes % 60, 60 * (minutes / 60))
  end
  #-- ------------------------------------------------------------------------
  #++
end
