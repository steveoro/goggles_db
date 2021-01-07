# frozen_string_literal: true

#
# = Version module
#
#   - version:  7.058
#   - author:   Steve A.
#
#   Semantic Versioning implementation.
module GogglesDb
  # Gem version
  VERSION = '0.1.58'

  module Version
    # Framework Core internal name.
    CORE    = 'C7'

    # Major version.
    MAJOR   = '7'

    # Minor version.
    MINOR   = '058'

    # Current build version.
    BUILD   = '20210107'

    # Full versioning for the current release (Framework + Core).
    FULL    = "#{MAJOR}.#{MINOR}.#{BUILD} (#{CORE} v. #{VERSION})"

    # Compact versioning label for the current release.
    COMPACT = "#{MAJOR.gsub('.', '')}#{MINOR}"

    # Current internal DB structure version
    # (this is independent from migrations and framework release)
    DB      = '1.58.01'

    # Pointless UNICODE emojis, just for fun:
    EMOJI_BUTTERFLY    = 'з== ( ▀ ͜͞ʖ▀) ==ε'
    EMOJI_FREESTYLE    = 'ᕙ ( ▀ ͜͞ʖ▀) /^'
    EMOJI_BREASTSTROKE = '( ▀ ͜͞ʖ▀)/^/^'
    EMOJI_BACKSTROKE   = '٩ (◔^◔) ۶'
    EMOJI_STRONGMAN    = 'ᕦ(ò_óˇ)ᕤ'
    EMOJI_TEDDYBEAR    = 'ʕ•ᴥ•ʔ'
    EMOJI_SHRUG        = '¯\_(ツ)_/¯'
  end
end
