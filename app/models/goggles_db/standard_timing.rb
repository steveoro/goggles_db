# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = StandardTiming model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  # Standard timings used to compute event scores during a specific season for all
  # swimmers enrolled to that season's Championship. (=> Championship records)
  #
  class StandardTiming < ApplicationRecord
    self.table_name = 'standard_timings'
    include TimingManageable

    belongs_to :season
    belongs_to :pool_type
    belongs_to :event_type
    belongs_to :gender_type
    belongs_to :category_type
    validates_associated :season
    validates_associated :pool_type
    validates_associated :event_type
    validates_associated :gender_type
    validates_associated :category_type

    has_one :season_type, through: :season

    default_scope do
      includes(
        :pool_type, :event_type, :gender_type, :category_type,
        :season, :season_type
      )
    end

    # Sorting scopes:
    scope :by_season,     ->(dir = :asc) { joins(:season).order('seasons.header_year': dir) }
    scope :by_event_type, ->(dir = :asc) { joins(:event_type).order('event_types.code': dir) }

    # Filtering scopes:
    scope :for_season,        ->(season) { where(season_id: season.id) }
    scope :for_pool_type,     ->(pool_type) { where(pool_type_id: pool_type.id) }
    scope :for_event_type,    ->(event_type) { where(event_type_id: event_type.id) }
    scope :for_gender_type,   ->(gender_type) { where(gender_type_id: gender_type.id) }
    scope :for_category_type, ->(category_type) { where(category_type_id: category_type.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the standard time for a given season, pool_type, event_type,
    # gender_type & category_type exists.
    def self.exists_for?(season, pool_type, event_type, gender_type, category_type)
      StandardTiming.exists?(season_id: season.id,
                             pool_type_id: pool_type.id,
                             event_type_id: event_type.id,
                             gender_type_id: gender_type.id,
                             category_type_id: category_type.id)
    end

    # Returns the first standard time found for a given season, pool_type, event_type,
    # gender_type & category_type; +nil+ otherwise.
    def self.find_first(season, pool_type, event_type, gender_type, category_type)
      StandardTiming.where(
        season_id: season.id,
        pool_type_id: pool_type.id,
        event_type_id: event_type.id,
        gender_type_id: gender_type.id,
        category_type_id: category_type.id
      ).first
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[season pool_type event_type gender_type category_type]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s,
        'display_label' => decorate.display_label(locale),
        'short_label' => decorate.short_label(locale)
      )
    end
  end
end
