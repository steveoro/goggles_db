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

    # Returns the comma-separated swimmers_ids as an array of integers.
    def swimmer_ids_array
      swimmers_ids.to_s.split(',').map(&:to_i).reject(&:zero?)
    end

    # Sets swimmers_ids from an array of integers (or strings).
    def swimmer_ids_array=(arr)
      self.swimmers_ids = Array(arr).compact_blank.map(&:to_i).join(',')
    end
  end
end
