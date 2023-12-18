# frozen_string_literal: true

#
# = Timing
#
#  - version:  7-0.5.21
#  - author:   Steve A.
#
#  Utility class to store timing data and to allow simple mathematical operations
#  between timings (delta, sum, ...).
#
class Timing
  include Comparable

  # === Members:
  #  - <tt>:hundredths</tt> => Integer value for hundredths of a second.
  #  - <tt>:seconds</tt> => Integer value for seconds.
  #  - <tt>:minutes</tt> => Integer value for minutes.
  #  - <tt>:hours</tt> => Integer value for hours.
  #  - <tt>:days</tt> => Integer value for days.
  attr_accessor :hundredths, :seconds, :minutes, :hours, :days

  # Creates a new instance.
  # Any missing option value defaults to 0.
  #
  # === Supported options:
  #  - <tt>:hundredths</tt> => Integer value for hundredths of a second.
  #  - <tt>:seconds</tt> => Integer value for seconds.
  #  - <tt>:minutes</tt> => Integer value for minutes.
  #  - <tt>:hours</tt> => Integer value for hours.
  #  - <tt>:days</tt> => Integer value for days.
  #
  def initialize(options = {})
    @hundredths = options&.fetch(:hundredths, 0).to_i
    @seconds = options&.fetch(:seconds, 0).to_i
    @minutes = options&.fetch(:minutes, 0).to_i
    @hours = options&.fetch(:hours, 0).to_i
    @days = options&.fetch(:days, 0).to_i
    # Adjust & round the result:
    from_hundredths(to_hundredths)
  end

  # Sets the instance to zero.
  #
  def clear
    @hundredths = 0
    @seconds = 0
    @minutes = 0
    @hours = 0
    @days = 0
    self
  end
  #-- -------------------------------------------------------------------------
  #++

  # Converts the current instance value to a total Number value of hundredths of a second.
  def to_hundredths
    @hundredths + (@seconds * 100) + (@minutes * 6000) +
      (@hours * 360_000) + (@days * 8_640_000)
  end

  # Checks if the current instance is zero.
  def zero?
    # NOTE: 'delegate <METHOD>, to: <OTHER_METHOD>' is somewhat broken in Ruby 2.7.
    # (See: https://eregon.me/blog/2021/02/13/correct-delegation-in-ruby-2-27-3.html)
    # Using a simple 'delegate' does not break the current timing spec, but yields failures later on when the concern is applied
    # to a shared abstract class like AbstractLap or AbstractResult during empty? or zero? checks where implicit blocks may be yield
    # as unexpected parameters.
    to_hundredths.zero?
  end

  # Checks if the current instance is positive.
  def positive?
    # (See NOTE above)
    to_hundredths.positive?
  end

  # Checks if the current instance is negative.
  def negative?
    # (See NOTE above)
    to_hundredths.negative?
  end

  alias empty? zero? # (new, old)

  # Sets the current instance value according to the total Number value of hundredths of a second
  # specified as a parameter.
  #
  # == Params:
  # - +hundredths_value+: the total number of hundredths of a second from which the timing instance must be set
  #
  def from_hundredths(hundredths_value)
    @days = hundredths_value / 8_640_000
    remainder = hundredths_value % 8_640_000
    @hours = remainder / 360_000
    remainder %= 360_000
    @minutes = remainder / 6000
    remainder %= 6000
    @seconds = remainder / 100
    remainder %= 100
    @hundredths = remainder
    self
  end

  # Converts the current instance to a readable string.
  # Zeros are always displayed for minutes, seconds and hundredths.
  def to_s
    compact_digit(days, 'd ') +
      compact_digit(hours, 'h ') +
      compact_digit(minutes, "'", single_zero: true) +
      compact_digit(seconds, '"', leading_zero: true) +
      compact_digit(hundredths, '', leading_zero: true)
  end

  # Commodity class method. Similar to +to_s+ method, but it doesn't include
  # members with non positive values in the output string.
  #
  def to_compact_s
    compact_digit(days, 'd ') +
      compact_digit(hours, 'h ') +
      compact_digit(minutes, "'") +
      compact_digit(seconds, '"', leading_zero: minutes.positive?) +
      compact_digit(hundredths, '', leading_zero: seconds.positive?)
  end
  #-- -------------------------------------------------------------------------
  #++

  # Returns a new instance containing as member values the sum of the current instance
  # with the one specified as a parameter.
  #
  # == Params:
  # - +other+: the other instance of Timing for the operator
  #
  def +(other)
    Timing.new(
      hundredths: @hundredths + other.hundredths,
      seconds: @seconds + other.seconds,
      minutes: @minutes + other.minutes,
      hours: @hours + other.hours,
      days: @days + other.days
    )
  end

  # Returns a new instance containing as member values the difference between
  # the current instance and the one specified as a parameter.
  #
  # == Params:
  # - +other+: the other instance of Timing for the operator
  #
  def -(other)
    Timing.new(
      hundredths: @hundredths - other.hundredths,
      seconds: @seconds - other.seconds,
      minutes: @minutes - other.minutes,
      hours: @hours - other.hours,
      days: @days - other.days
    )
  end

  # Returns a new instance with the overall timing value multipled by the
  # scalar number specified as a parameter.
  #
  # == Params:
  # - +other+: an Integer-only value used for the multiplication; fractional
  #   numbers cannot be used due to approximation in to_hundredths / from_hundredths
  #   conversion.
  #
  def *(other)
    raise(ArgumentError, 'Argument number must be of a Numeric kind.') unless other.is_a?(Integer)

    Timing.new.from_hundredths(to_hundredths * other)
  end

  # Equals operator. Returns true if the two Timing objects have the same
  # value. +false+ otherwise.
  #
  # == Params:
  # - +other+: the other instance of Timing for the comparison
  #
  def ==(other)
    return false unless other.instance_of?(Timing)

    @days == other.days &&
      @hours == other.hours &&
      @minutes == other.minutes &&
      @seconds == other.seconds &&
      @hundredths == other.hundredths
  end

  # Comparable operator. Returns -1, 0, or 1 depending on the order between the
  # two Timing objects.
  # Returns always 1 for nil values.
  #
  # (See +Comparable+ class in Ruby library)
  #
  # == Params:
  # - +other+: the other instance of Timing for the comparison
  #
  def <=>(other)
    raise ArgumentError, "the specified #{other.class.name} is neither a Timing or nil." unless other.nil? || other.instance_of?(Timing)

    other.nil? ? 1 : to_hundredths <=> other.to_hundredths
  end
  #-- -------------------------------------------------------------------------
  #++

  # Commodity class method. Same as to_s.
  # Normalizes the specified values into the correct number of units.
  # Any missing option value defaults to 0.
  #
  # === Supported options:
  #  - <tt>:hundredths</tt> => Integer value for hundredths of a second.
  #  - <tt>:seconds</tt> => Integer value for seconds.
  #  - <tt>:minutes</tt> => Integer value for minutes.
  #  - <tt>:hours</tt> => Integer value for hours.
  #  - <tt>:days</tt> => Integer value for days.
  #
  def self.to_s(options = {})
    Timing.new(
      hundredths: options&.fetch(:hundredths, 0).to_i,
      seconds: options&.fetch(:seconds, 0).to_i,
      minutes: options&.fetch(:minutes, 0).to_i,
      hours: options&.fetch(:hours, 0).to_i,
      days: options&.fetch(:days, 0).to_i
    ).to_s
  end

  # Commodity class method. Same as to_compact_s.
  # Normalizes the specified values into the correct number of units.
  # Any missing option value defaults to 0.
  #
  # === Supported options:
  #  - <tt>:hundredths</tt> => Integer value for hundredths of a second.
  #  - <tt>:seconds</tt> => Integer value for seconds.
  #  - <tt>:minutes</tt> => Integer value for minutes.
  #  - <tt>:hours</tt> => Integer value for hours.
  #  - <tt>:days</tt> => Integer value for days.
  #
  def self.to_compact_s(options = {})
    Timing.new(
      hundredths: options&.fetch(:hundredths, 0).to_i,
      seconds: options&.fetch(:seconds, 0).to_i,
      minutes: options&.fetch(:minutes, 0).to_i,
      hours: options&.fetch(:hours, 0).to_i,
      days: options&.fetch(:days, 0).to_i
    ).to_compact_s
  end
  #-- -------------------------------------------------------------------------
  #++

  # Outputs the specified value of seconds in an hour-format string (Hh MM' SS").
  # It skips the output of any 2-digit part when its value is 0.
  #
  # (This is true for hours, minutes, seconds and even hundredths, making this method
  # ideal to represent a total duration or span of time, without displaying the
  # non-significant members).
  #
  # == Params:
  # - +total_seconds+: the total number of seconds for the formatted label
  #
  def self.to_hour_string(total_seconds)
    hours = total_seconds.to_i / 3600
    remainder = total_seconds.to_i % 3600
    minutes = remainder / 60
    seconds = remainder % 60
    to_compact_s(seconds:, minutes:, hours:)
  end

  # Outputs the specified value of seconds in a minute-format (M'SS").
  # It skips the output of the minutes when 0.
  #
  # == Params:
  # - +total_seconds+: the total number of seconds for the formatted label
  #
  def self.to_minute_string(total_seconds)
    minutes = total_seconds.to_i / 60
    seconds = total_seconds.to_i % 60
    to_compact_s(seconds:, minutes:)
  end

  # Outputs the specified value of seconds in a "pause in seconds" format (P.SS").
  # Returns an empty string if the value is 0.
  #
  # == Params:
  # - +total_seconds+: the total number of seconds for the formatted label
  #
  def self.to_formatted_pause(total_seconds)
    # Note that with pause > 60", Timing conversion won't be perfomed using to_compact_s
    total_seconds.to_i.positive? ? " p.#{Timing.to_compact_s(seconds: total_seconds.to_i)}" : ''
  end

  # Outputs the specified value of seconds in a "Start-Rest " format (S-R: M'.SS").
  # Returns an empty string if the value is 0.
  #
  # == Params:
  # - +total_seconds+: the total number of seconds for the formatted label
  #
  def self.to_formatted_start_and_rest(total_seconds)
    total_seconds.to_i.positive? ? " SR.#{Timing.to_minute_string(total_seconds.to_i)}" : ''
  end
  #-- -------------------------------------------------------------------------
  #++

  private

  # Displays the +value+ as string followed by the +char_key+ but only if the value is non-zero.
  # (Hides zeros otherwise.)
  #
  # == Options:
  #
  # - +leading_zero+: +true+, single digits will be returned as double digits prefixed with '0';
  #                           a zero will become '00';
  # - +single_zero+: +true+, single digits will NOT be prefixed with '0';
  #                          a zero will remain displayed as '0'.
  #
  # When both options are false, zero values won't be displayed and an empty string will be returned.
  #
  def compact_digit(value, char_key, leading_zero: false, single_zero: false)
    actual_layout = leading_zero && !single_zero ? '%<val>02.0f%<key>s' : '%<val>s%<key>s'
    # Bail out with an empty string if no option is used and the value is zero:
    return '' if value.to_i.zero? && !leading_zero && !single_zero

    format(actual_layout, val: value, key: char_key)
  end
end
