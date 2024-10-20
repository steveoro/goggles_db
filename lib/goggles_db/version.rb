# frozen_string_literal: true

#
# = Version module
# - author: Steve A.
#
module GogglesDb
  # Public gem version (uses Semantic versioning)
  VERSION = '0.7.20'

  # == Versioning codes
  #
  # Framework Core internal name & versioning constants.
  #
  # Includes core, major, minor, build & composed labels
  # for quick reference on pages.
  #
  module Version
    CORE  = 'C7'
    MAJOR = '0'
    MINOR = '7'
    PATCH = '20'
    BUILD = '20241018'

    # Full label
    FULL = "#{MAJOR}.#{MINOR}.#{PATCH} (#{CORE}-#{BUILD})".freeze

    # Compact label
    SEMANTIC = "#{MAJOR}.#{MINOR}.#{PATCH}".freeze
    DB = '2.07.6' # Internal DB structure (frozen @ <minor>.<patch>.<seq> from last migration)

    # Pointless UNICODE emojis (just for fun):
    EMOJI_BUTTERFLY    = 'з== ( ▀ ͜͞ʖ▀) ==ε'
    EMOJI_FREESTYLE    = 'ᕙ ( ▀ ͜͞ʖ▀) /^'
    EMOJI_BREASTSTROKE = '( ▀ ͜͞ʖ▀)/^/^'
    EMOJI_BACKSTROKE   = '٩ (◔^◔) ۶'
    EMOJI_STRONGMAN    = 'ᕦ(ò_óˇ)ᕤ'
    EMOJI_TEDDYBEAR    = 'ʕ•ᴥ•ʔ'
    EMOJI_SHRUG        = '¯\_(ツ)_/¯'
    EMOJI_HELLO        = '٩( ▀ ͜͞ʖ▀)۶'
  end
end
