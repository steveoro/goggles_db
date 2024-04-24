# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::GoggleCup
  #
  # - version:  7-0.7.10
  # - author:   Steve A.
  #
  class GoggleCup < ApplicationRecord
    self.table_name = 'goggle_cups'

    belongs_to :team
    validates_associated :team

    # TODO
  end
end
