# frozen_string_literal: true

#
# = Version module
#
#   - version:  7.001
#   - author:   Steve A.
#
#   Semantic Versioning implementation.
module GogglesDb
  # Gem version
  VERSION = '0.1.3'

  module Version
    # Framework Core internal name.
    CORE    = 'C7'

    # Major version.
    MAJOR   = '7'

    # Minor version.
    MINOR   = '003'

    # Current build version.
    BUILD   = '20200914'

    # Full versioning for the current release (Framework + Core).
    FULL    = "#{MAJOR}.#{MINOR}.#{BUILD} (#{CORE} v. #{VERSION})"

    # Compact versioning label for the current release.
    COMPACT = "#{MAJOR.gsub('.', '')}#{MINOR}"

    # Current internal DB structure version
    # (this is independent from migrations and framework release)
    DB      = '1.28.00'
  end
end
