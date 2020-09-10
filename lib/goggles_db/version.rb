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
  VERSION = '0.1.0'

  module Version
    # Framework Core internal name.
    CORE    = 'C7'

    # Major version.
    MAJOR   = '7'

    # Minor version.
    MINOR   = '001'

    # Current build version.
    BUILD   = '20200907'

    # Full versioning for the current release (Framework + Core).
    FULL    = "#{MAJOR}.#{MINOR}.#{BUILD} (#{CORE} v. #{VERSION})"

    # Compact versioning label for the current release.
    COMPACT = "#{MAJOR.gsub('.', '')}#{MINOR}"

    # Current internal DB structure version
    # (this is independent from migrations and framework release)
    DB      = '1.28.00'
  end
end
