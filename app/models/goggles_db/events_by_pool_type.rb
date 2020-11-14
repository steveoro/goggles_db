# frozen_string_literal: true

module GogglesDb
  #
  # = EventsByPoolType model
  #
  # This entity is assumed to be pre-seeded on the database.
  #
  #   - version:  7.030
  #   - authors:  Steve A.
  #
  class EventsByPoolType < ApplicationRecord
    self.table_name = 'events_by_pool_types'

    belongs_to :pool_type
    validates :pool_type, presence: true
    validates_associated :pool_type

    belongs_to :event_type
    validates :event_type, presence: true
    validates_associated :event_type

    has_one :stroke_type, through: :event_type

    delegate :relay?, to: :event_type

    # Memoize all values for virtual scopes:
    all.joins(:stroke_type).includes(:stroke_type).order(:style_order).each do |row|
      class_eval do
        @only_relays ||= []
        @only_relays << row if row&.relay?
        @only_individuals ||= []
        @only_individuals << row unless row&.relay?
        @eventable ||= []
        @eventable << row if row&.pool_type&.eventable? && row&.stroke_type&.eventable?
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    scope :by_pool_type,  -> { joins(:event_type, :pool_type).order('pool_types.length_in_meters, event_types.style_order') }
    scope :by_event_type, -> { joins(:event_type, :pool_type).order('event_types.style_order, pool_types.length_in_meters') }

    # Filtering scopes:
    scope :for_pool_type, ->(pool_type) { joins(:pool_type).where(['pool_types.id = ?', pool_type.id]) }
    scope :event_length_between, lambda { |min_length, max_length|
      joins(:event_type)
        .where(
          '(event_types.length_in_meters >= ?) AND (event_types.length_in_meters <= ?)',
          min_length, max_length
        )
    }

    # Virtual scopes:
    # rubocop:disable Style/TrivialAccessors
    def self.eventable
      @eventable
    end

    def self.only_relays
      @only_relays
    end

    def self.only_individuals
      @only_individuals
    end
    # rubocop:enable Style/TrivialAccessors
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if both the PoolType & the StrokeType are suitable for standard Meeting events.
    def eventable?
      stroke_type.eventable? && pool_type.eventable?
    end

    # Override: includes all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'pool_type' => pool_type.attributes,
        'event_type' => event_type.attributes,
        'stroke_type' => stroke_type.attributes
      ).to_json(options)
    end
  end
end
