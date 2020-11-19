# frozen_string_literal: true

module GogglesDb
  #
  # = CategoryType model
  #
  #   - version:  7.010
  #   - author:   Steve A.
  #
  class CategoryType < ApplicationRecord
    self.table_name = 'category_types'

    belongs_to :season
    validates :season, presence: true
    validates_associated :season

    has_one :season_type, through: :season
    has_one :federation_type, through: :season_type

    validates :code, presence: { length: { within: 1..7 }, allow_nil: false }
    validates :federation_code, length: { within: 1..2 }
    validates :description,     length: { maximum: 100 }
    validates :short_name,      length: { maximum: 50 }
    validates :group_name,      length: { maximum: 50 }
    validates :age_begin,       length: { maximum: 3 }
    validates :age_end,         length: { maximum: 3 }

    alias_attribute :relay?, :is_a_relay
    alias_attribute :undivided?, :is_undivided

    # Sorting scopes:
    scope :by_age, ->(dir = 'ASC') { order(dir == 'ASC' ? 'age_begin ASC' : 'age_begin DESC') }

    # Filtering scopes:
    scope :eventable,         -> { where(is_out_of_race: false) }
    scope :relays,            -> { where(is_a_relay: true) }
    scope :individuals,       -> { where(is_a_relay: false) }
    scope :only_undivided,    -> { where(is_undivided: true) }
    scope :only_gender_split, -> { where(is_undivided: false) }
    scope :for_season_type,   ->(season_type) { includes(:season_type).joins(:season_type).where(['season_types.id = ?', season_type.id]) }
    scope :for_season,        ->(season)      { includes(:season).joins(:season).where(['season_id = ?', season.id]) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this category type will count for the overall rankings in an event
    def eventable?
      !is_out_of_race
    end
  end
end
