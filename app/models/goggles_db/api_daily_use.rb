# frozen_string_literal: true

module GogglesDb
  #
  # = APIDailyUse model
  #
  #   - version:  7.075
  #   - author:   Steve A.
  #
  # Stores overall count of API calls for each (route, day).
  # Used to exatract periodic stats.
  #
  class APIDailyUse < ApplicationRecord
    self.table_name = 'api_daily_uses'

    # Stores 'request.path':
    validates :route, presence: { length: { within: 1..255, allow_nil: false } }

    validates :day, presence: true
    validates :count, presence: true, numericality: true

    # Sorting scopes:
    scope :by_date, ->(dir = :asc) { order(day: dir) }

    # Filtering scopes:
    scope :for_date,  ->(date = Date.today) { where(day: date).order(:route) }
    scope :for_route, ->(route) { where(route: route).order(:day) }
    #-- ------------------------------------------------------------------------
    #++

    # Increases the daily usage counter for the specified route.
    # Automatically creates the (route, day) row if missing.
    # The (route, day) tuple is unique: 1 route string for each day value.
    #
    # === Params:
    # - route: allegedly a unique route string, but could be any non-empty string;
    #          it doesn't need to correspond to an actual API route but it would be better
    #          to have any IDs stripped out, to reduce row cluttering.
    # - day: a Date instance; defaults to +today+.
    #
    # === Note:
    # 'route' does not need to correspond to an actual API route; it can be
    # any valid string.
    #
    def self.increase_for!(route, day = Date.today)
      counter_row = APIDailyUse.create_or_find_by!(route: route, day: day)
      counter_row.increment!(:count)
    end
  end
end
