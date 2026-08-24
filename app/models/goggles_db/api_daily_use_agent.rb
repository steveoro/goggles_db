# frozen_string_literal: true

module GogglesDb
  #
  # = APIDailyUseAgent model
  #
  #   - version:  7-0.1.00
  #   - author:   Steve A.
  #
  # Stores overall count of user-agent strings for each (user_agent, day).
  # Used to extract periodic stats about the most used agents.
  #
  class APIDailyUseAgent < ApplicationRecord
    self.table_name = 'api_daily_use_agents'

    validates :user_agent, presence: { length: { within: 1..255, allow_nil: false } }
    validates :day, presence: true
    validates :count, presence: true, numericality: true

    # Sorting scopes:
    scope :by_date, ->(dir = :asc) { order(day: dir) }

    # Filtering scopes:
    scope :for_date,  ->(date = Time.zone.today) { where(day: date).order(:user_agent) }
    scope :for_agent, ->(user_agent) { where(user_agent:).order(:day) }
    #-- ------------------------------------------------------------------------
    #++

    # Increases the daily usage counter for the specified user_agent string.
    # Automatically creates the (user_agent, day) row if missing.
    # The (user_agent, day) tuple is unique: 1 user_agent string for each day value.
    #
    # === Params:
    # - user_agent: the raw user-agent string; blank/nil values are stored as 'unknown'.
    # - day: a Date instance; defaults to +today+.
    #
    # rubocop:disable-next Rails/SkipsModelValidations
    def self.increase_for!(user_agent, day = Time.zone.today)
      safe_agent = user_agent.to_s.strip.first(255).presence || 'unknown'
      counter_row = APIDailyUseAgent.create_or_find_by!(user_agent: safe_agent, day:)
      counter_row.increment!(:count)
    end

    # Returns the +limit+ most used user-agent strings between +day_from+ and +day_to+,
    # with their total count summed across the period.
    def self.top_agents(day_from:, day_to:, limit: 10)
      where(day: day_from..day_to)
        .group(:user_agent)
        .order('SUM(count) DESC')
        .select(:user_agent, 'SUM(count) AS total_count')
        .limit(limit)
    end
  end
end
