# frozen_string_literal: true

module GogglesDb
  #
  # = RecordType localizable look-up entity
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class RecordType < AbstractLookupEntity
    self.table_name = 'record_types'
  end
end
