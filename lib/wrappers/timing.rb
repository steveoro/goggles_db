# frozen_string_literal: true

#
# = Timing
#   - Goggles framework vers.:  7.036
#   - author: Steve A.
#
#  Utility class to store timing data and to allow simple mathematical operations
#  between timings (delta, sum, ...).
#
# === Members:
#  - <tt>:hundreds</tt> => Integer value for hundreds of a second.
#  - <tt>:seconds</tt> => Integer value for seconds.
#  - <tt>:minutes</tt> => Integer value for minutes.
#  - <tt>:hours</tt> => Integer value for hours.
#  - <tt>:days</tt> => Integer value for days.
#
class Timing
  include Comparable

  attr_accessor :hundreds, :seconds, :minutes, :hours, :days

  # Creates a new instance.
  # The ascending precision of the parameters allows to skip rarely used ones.
  #
  def initialize(hundreds = 0, seconds = 0, minutes = 0, hours = 0, days = 0)
    @hundreds = hundreds.to_i
    @seconds = seconds.to_i
    @minutes = minutes.to_i
    @hours = hours.to_i
    @days = days.to_i
    # Adjust & round the result:
    from_hundreds(to_hundreds)
  end

  # Sets the instance to zero.
  #
  def clear
    @hundreds = 0
    @seconds = 0
    @minutes = 0
    @hours = 0
    @days = 0
    self
  end
  #-- -------------------------------------------------------------------------
  #++

  # Converts the current instance to a readable string.
  def to_s
    (days.to_i.positive? ? "#{days}d " : '') +
      (hours.to_i.positive? ? "#{hours}h " : '') +
      format(
        minutes.to_i.positive? ? "%2s'%02.0f\"%02.0f" : "%2s'%2s\"%02.0f",
        minutes.to_i, seconds.to_i, hundreds.to_i
      )
  end

  # Converts the current instance value to total Fixnum value of hundreds of a second.
  def to_hundreds
    @hundreds + @seconds * 100 + @minutes * 6000 +
      @hours * 360_000 + @days * 8_640_000
  end

  # Sets the current instance value according to the total Fixnum value of hundreds of a second
  # specified as a parameter.
  #
  def from_hundreds(hundreds_value)
    @days = hundreds_value / 8_640_000
    remainder = hundreds_value % 8_640_000
    @hours = remainder / 360_000
    remainder = remainder % 360_000
    @minutes = remainder / 6000
    remainder = remainder % 6000
    @seconds = remainder / 100
    remainder = remainder % 100
    @hundreds = remainder
    self
  end
  #-- -------------------------------------------------------------------------
  #++

  # Returns a new instance containing as member values the sum of the current instance
  # with the one specified as a parameter.
  #
  def +(other)
    Timing.new(
      @hundreds + other.hundreds,
      @seconds + other.seconds,
      @minutes + other.minutes,
      @hours + other.hours,
      @days + other.days
    )
  end

  # Returns a new instance containing as member values the differemce between
  # the current instance and the one specified as a parameter.
  #
  def -(other)
    Timing.new(
      @hundreds - other.hundreds,
      @seconds - other.seconds,
      @minutes - other.minutes,
      @hours - other.hours,
      @days - other.days
    )
  end

  # Equals operator. Returns true if the two Timing objects have the same
  # value. +false+ otherwise.
  #
  def ==(other)
    return false unless other.instance_of?(Timing)

    (
      @days == other.days &&
      @hours == other.hours &&
      @minutes == other.minutes &&
      @seconds == other.seconds &&
      @hundreds == other.hundreds
    )
  end

  # Comparable operator. Returns -1, 0, or 1 depending on the order between the
  # two Timing objects.
  # Returns always 1 for nil values.
  #
  # (See +Comparable+ class in Ruby library)
  #
  def <=>(other)
    raise ArgumentError, "the specified #{other.class.name} is neither a Timing or nil." unless other.nil? || other.instance_of?(Timing)

    other.nil? ? 1 : to_hundreds <=> other.to_hundreds
  end
  #-- -------------------------------------------------------------------------
  #++

  # Commodity class method. Same as to_s.
  #
  def self.to_s(hundreds = 0, seconds = 0, minutes = 0, hours = 0, days = 0)
    Timing.new(hundreds, seconds, minutes, hours, days).to_s
  end

  # Commodity class method. Similar to +to_s+ method, but it doesn't include
  # members with non positive values in the output string.
  #
  def self.to_compact_s(hundreds = 0, seconds = 0, minutes = 0, hours = 0, days = 0)
    (days.to_i.zero?       ? '' : "#{days}d ") +
      (hours.to_i.zero?    ? '' : "#{hours}h ") +
      (minutes.to_i.zero?  ? '' : format("%<value>2s'", value: minutes)) +
      (if seconds.to_i.zero?
         ''
       else
         format((minutes.positive? ? '%<value>02.0f"' : '%<value>2s"'), value: seconds)
       end) +
      (hundreds.to_i.zero? ? '' : format('%<value>02.0f', value: hundreds))
  end

  # Outputs the specified value of seconds in an hour-format string (Hh MM' SS").
  # It skips the output of any 2-digit part when its value is 0.
  # (This is true for hours, minutes, seconds and even hundreds, making this method
  # ideal to represent a total duration or span of time, without displaying the
  # non-significant members).
  #
  def self.to_hour_string(total_seconds)
    hours = total_seconds.to_i / 3600
    remainder = total_seconds.to_i % 3600
    minutes = remainder / 60
    seconds = remainder % 60
    to_compact_s(0, seconds, minutes, hours)
  end

  # Outputs the specified value of seconds in a minute-format (M'SS").
  # It skips the output of the minutes when 0.
  #
  def self.to_minute_string(total_seconds)
    minutes = total_seconds.to_i / 60
    seconds = total_seconds.to_i % 60
    to_compact_s(0, seconds, minutes)
  end
  #-- -------------------------------------------------------------------------
  #++

  # Outputs the specified value of seconds in a "pause in seconds" format (P.SS").
  # Returns an empty string if the value is 0.
  #
  def self.to_formatted_pause(total_seconds)
    # Note that with pause > 60", Timing conversion won't be perfomed using to_compact_s
    total_seconds.to_i.positive? ? " p.#{Timing.to_compact_s(0, total_seconds.to_i)}" : ''
  end

  # Outputs the specified value of seconds in a "Start-Rest " format (S-R: M'.SS").
  # Returns an empty string if the value is 0.
  #
  def self.to_formatted_start_and_rest(total_seconds)
    total_seconds.to_i.positive? ? " SR.#{Timing.to_minute_string(total_seconds.to_i)}" : ''
  end
  #-- -------------------------------------------------------------------------
  #++
end
