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

    validates :season_year, presence: true,
                            numericality: { only_integer: true, greater_than: 2000 }
    validates :description, presence: true,
                            uniqueness: { scope: %i[team_id season_year] }
  end
end
