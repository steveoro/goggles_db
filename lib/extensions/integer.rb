# rubocop:disable Style/FrozenStringLiteralComment

# Adds support for roman numeral parsing and decoding
#
class Integer
  unless defined? ROMAN_NUMBERS
    ROMAN_NUMBERS = {
      1000 => 'M',
      900 => 'CM',
      500 => 'D',
      400 => 'CD',
      100 => 'C',
      90 => 'XC',
      80 => 'LXXX',
      50 => 'L',
      40 => 'XL',
      10 => 'X',
      9 => 'IX',
      8 => 'VIII',
      5 => 'V',
      4 => 'IV',
      1 => 'I'
    }.freeze
  end
  #-- -------------------------------------------------------------------------
  #++

  # Converts the value to a Roman numeral
  def to_roman
    n = self
    roman = ''
    ROMAN_NUMBERS.each do |value, letter|
      roman << letter * (n / value)
      n = n % value
    end
    roman
  end
  #-- -------------------------------------------------------------------------
  #++

  # Parses a Roman numeral to ints Integer value
  def self.from_roman(roman)
    r = roman.upcase
    n = 0
    ROMAN_NUMBERS.each { |num, sym| n += num while r.sub!(/^#{sym}/, '') }
    n
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
