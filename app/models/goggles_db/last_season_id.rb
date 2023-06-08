# frozen_string_literal: true

module GogglesDb
  #
  # = LastSeasonId Scenic View model
  #
  # See https://github.com/scenic-views/scenic
  #
  #   - version:  7-0.5.12
  #   - author:   Steve A.
  #
  class LastSeasonId < ApplicationRecord
    self.table_name = 'last_seasons_ids'

    belongs_to :searchable, polymorphic: true

    # (Override) This is a view and it's always R/O
    def readonly?
      # Not strictly necessary, but it will prevent Rails from calling save, which would fail anyway.
      true
    end
  end
end
