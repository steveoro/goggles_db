# frozen_string_literal: true

require 'wrappers/timing'

module GogglesDb
  #
  # = SeasonPersonalStandard model
  #
  #   - version:  7.036
  #   - author:   Steve A.
  #
  # Standard timings used to compute event scores during a specific season and relative
  # to a *specific* swimmer. (=> Personal best-records for each athlete)
  #
  class SeasonPersonalStandard < ApplicationRecord
    self.table_name = 'season_personal_standards'
    include TimingManageable

    belongs_to :season
    belongs_to :swimmer
    belongs_to :pool_type
    belongs_to :event_type
    validates_associated :season
    validates_associated :swimmer
    validates_associated :pool_type
    validates_associated :event_type

    has_one :season_type, through: :season

    # Sorting scopes:
    scope :by_season,     ->(dir = :asc) { joins(:season).order('seasons.header_year': dir) }
    scope :by_event_type, ->(dir = :asc) { joins(:event_type).order('event_types.code': dir) }

    # Filtering scopes:
    scope :for_season,     ->(season)     { where(season_id: season.id) }
    scope :for_swimmer,    ->(swimmer)    { where(swimmer_id: swimmer.id) }
    scope :for_pool_type,  ->(pool_type)  { where(pool_type_id: pool_type.id) }
    scope :for_event_type, ->(event_type) { where(event_type_id: event_type.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the standard time for a given season, swimmer, pool_type & event_type exists.
    def self.exists_for?(season, swimmer, pool_type, event_type)
      SeasonPersonalStandard.exists?(season_id: season.id,
                                     swimmer_id: swimmer.id,
                                     pool_type_id: pool_type.id,
                                     event_type_id: event_type.id)
    end

    # Returns the first standard time found for a given season, swimmer, pool_type & event_type;
    # +nil+ otherwise.
    def self.find_first(season, swimmer, pool_type, event_type)
      SeasonPersonalStandard.where(
        season_id: season.id,
        swimmer_id: swimmer.id,
        pool_type_id: pool_type.id,
        event_type_id: event_type.id
      ).first
    end
  end
end
