# frozen_string_literal: true

#
# = Version module
#
#   - version:  7.79
#   - author:   Steve A.
#
module GogglesDb
  # Public gem version (uses Semantic versioning)
  VERSION = '0.1.79'

  # == Versioning codes
  #
  # Framework Core internal name & versioning constants.
  #
  # Includes core, major, minor, build & composed labels
  # for quick reference on pages.
  #
  module Version
    CORE    = 'C7'
    MAJOR   = '7'
    MINOR   = '79' # (this should be = patch version)
    BUILD   = '20210224'

    # Full label
    FULL    = "#{MAJOR}.#{MINOR}.#{BUILD} (#{CORE} v. #{VERSION})"

    # Compact label
    COMPACT = "#{MAJOR.gsub('.', '')}#{MINOR}"
    DB      = '1.79.0' # Internal DB structure (frozen <minor>.<patch>.<seq> from last migration)

    # Pointless UNICODE emojis (just for fun):
    EMOJI_BUTTERFLY    = 'з== ( ▀ ͜͞ʖ▀) ==ε'
    EMOJI_FREESTYLE    = 'ᕙ ( ▀ ͜͞ʖ▀) /^'
    EMOJI_BREASTSTROKE = '( ▀ ͜͞ʖ▀)/^/^'
    EMOJI_BACKSTROKE   = '٩ (◔^◔) ۶'
    EMOJI_STRONGMAN    = 'ᕦ(ò_óˇ)ᕤ'
    EMOJI_TEDDYBEAR    = 'ʕ•ᴥ•ʔ'
    EMOJI_SHRUG        = '¯\_(ツ)_/¯'
  end
end
