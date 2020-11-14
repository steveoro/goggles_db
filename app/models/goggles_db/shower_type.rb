# frozen_string_literal: true

module GogglesDb
  #
  # = ShowerType localizable look-up entity
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class ShowerType < ApplicationLookupEntity
    self.table_name = 'shower_types'
  end
end
