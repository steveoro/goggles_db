# frozen_string_literal: true

module GogglesDb
  #
  # = APIDailyUse model
  #
  #   - version:  7-0.5.10
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
    scope :for_date,  ->(date = Time.zone.today) { where(day: date).order(:route) }
    scope :for_route, ->(route) { where(route:).order(:day) }
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
    # rubocop:disable-next Rails/SkipsModelValidations
    def self.increase_for!(route, day = Time.zone.today)
      counter_row = APIDailyUse.create_or_find_by!(route:, day:)
      counter_row.increment!(:count)
    end

    # Returns the +limit+ most requested non-IP routes between +day_from+ and +day_to+,
    # with their total count summed across the period.
    def self.top_routes(day_from:, day_to:, limit: 10)
      where(day: day_from..day_to)
        .where.not('route LIKE ?', 'REQ-%')
        .group(:route)
        .order('SUM(count) DESC')
        .select(:route, 'SUM(count) AS total_count')
        .limit(limit)
    end

    # Returns the +limit+ most active IP routes (REQ-<ip>) whose total count exceeds
    # +threshold+ between +day_from+ and +day_to+.
    def self.top_ip_routes(day_from:, day_to:, threshold: 500, limit: 10)
      where(day: day_from..day_to)
        .where('route LIKE ?', 'REQ-%')
        .group(:route)
        .having('SUM(count) > ?', threshold)
        .order('SUM(count) DESC')
        .select(:route, 'SUM(count) AS total_count')
        .limit(limit)
    end

    # Returns a simple Hash with overall, IP and non-IP request totals
    # for the specified period.
    def self.daily_totals(day_from:, day_to:)
      scope = where(day: day_from..day_to)
      {
        requests: scope.sum(:count),
        ip_requests: scope.where('route LIKE ?', 'REQ-%').sum(:count),
        route_requests: scope.where.not('route LIKE ?', 'REQ-%').sum(:count)
      }
    end
  end
end
