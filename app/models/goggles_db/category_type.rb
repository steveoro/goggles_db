# frozen_string_literal: true

module GogglesDb
  #
  # = CategoryType model
  #
  #   - version:  7-0.3.33
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

    # Sorting scopes:
    scope :by_age, ->(dir = :asc) { order(age_begin: dir) }

    # Filtering scopes:
    scope :eventable,         -> { where(out_of_race: false) }
    scope :relays,            -> { where(relay: true) }
    scope :individuals,       -> { where(relay: false) }
    scope :only_undivided,    -> { where(undivided: true) }
    scope :only_gender_split, -> { where(undivided: false) }
    scope :for_season_type,   ->(season_type) { includes(:season_type).joins(:season_type).where('season_types.id': season_type.id) }
    scope :for_season,        ->(season)      { includes(:season).joins(:season).where(season_id: season.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this category type will count for the overall rankings in an event
    def eventable?
      !out_of_race
    end

    # Override: include the minimum required 1st-level attributes & associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Override: includes all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(minimal_associations).to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    def minimal_associations
      {
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'season' => season.minimal_attributes
      }
    end
  end
end
