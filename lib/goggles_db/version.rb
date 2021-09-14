# frozen_string_literal: true

#
# = Version module
#
#   - version:  7-0.3.31
#   - author:   Steve A.
#
module GogglesDb
  # Public gem version (uses Semantic versioning)
  VERSION = '0.3.31'

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
    MINOR = '3'
    PATCH = '31'
    BUILD = '20210914'

    # Full label
    FULL = "#{MAJOR}.#{MINOR}.#{PATCH} (#{CORE}-#{BUILD})"

    # Compact label
    SEMANTIC = "#{MAJOR}.#{MINOR}.#{PATCH}"
    DB = '1.92.3' # Internal DB structure (frozen @ <minor>.<patch>.<seq> from last migration)

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
