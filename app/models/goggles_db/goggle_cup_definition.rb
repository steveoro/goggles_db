# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::GoggleCupStandard
  #
  # - version:  7-0.7.10
  # - author:   Steve A.
  #
  class GoggleCupDefinition < ApplicationRecord
    self.table_name = 'goggle_cup_definitions'

    belongs_to :goggle_cup
    belongs_to :season

    validates_associated :goggle_cup
    validates_associated :season

    # TODO
  end
end
