# frozen_string_literal: true

module GogglesDb
  #
  # = EventsByPoolType model
  #
  # This entity is assumed to be pre-seeded on the database.
  #
  #   - version:  7-0.6.30
  #   - authors:  Steve A.
  #
  class EventsByPoolType < ApplicationRecord
    self.table_name = 'events_by_pool_types'

    belongs_to :pool_type
    validates_associated :pool_type

    belongs_to :event_type
    validates_associated :event_type

    has_one :stroke_type, through: :event_type

    default_scope { includes(:pool_type, :event_type, :stroke_type) }

    delegate :length_in_meters, to: :event_type
    delegate :relay?,           to: :event_type

    # Memoize all values for virtual scopes:
    class_eval do
      all.includes(:pool_type, :event_type, :stroke_type)
         .joins(:pool_type, :event_type, :stroke_type).order(:style_order)
         .find_each do |row|
        @all_relays ||= []
        @all_relays << row if row&.relay?
        @all_individuals ||= []
        @all_individuals << row unless row&.relay?
        @all_eventable ||= []
        @all_eventable << row if row&.pool_type&.eventable? && row&.stroke_type&.eventable?
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    scope :by_pool_type,  -> { joins(:event_type, :pool_type).order('pool_types.length_in_meters, event_types.style_order') }
    scope :by_event_type, -> { joins(:event_type, :pool_type).order('event_types.style_order, pool_types.length_in_meters') }

    # Filtering scopes:
    scope :relays,        -> { joins(:event_type).where('event_types.relay': true) }
    scope :individuals,   -> { joins(:event_type).where('event_types.relay': false) }
    scope :eventable, lambda {
      joins(:stroke_type)
        .where(
          'stroke_types.id': StrokeType::EVENTABLE_IDS,
          pool_type_id: PoolType::EVENTABLE_IDS
        )
    }
    scope :for_pool_type, ->(pool_type) { where(pool_type_id: pool_type.id) }
    scope :event_length_between, lambda { |min_length, max_length|
      joins(:event_type)
        .where(
          '(event_types.length_in_meters >= ?) AND (event_types.length_in_meters <= ?)',
          min_length, max_length
        )
    }
    # rubocop:disable Style/TrivialAccessors
    #-- ------------------------------------------------------------------------
    #++

    # Array of all possible event type combinations (pool types x event types).
    # Choosing one association row among this list guarantees that the tuple is a valid event-pool combination.
    # Includes both relay- & individual-event types.
    def self.all_eventable
      @all_eventable
    end

    # Array of all possible event type combinations (pool types x event types) but only for relays.
    def self.all_relays
      @all_relays
    end

    # Array of all possible event type combinations (pool types x event types) but only for invididual events.
    def self.all_individuals
      @all_individuals
    end
    # rubocop:enable Style/TrivialAccessors
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if both the PoolType & the StrokeType are suitable for standard Meeting events.
    def eventable?
      stroke_type.eventable? && pool_type.eventable?
    end
  end
end
