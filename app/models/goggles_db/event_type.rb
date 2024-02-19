# frozen_string_literal: true

module GogglesDb
  #
  # = EventType model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class EventType < AbstractLookupEntity
    self.table_name = 'event_types'

    belongs_to :stroke_type
    validates_associated :stroke_type

    default_scope { includes(:stroke_type) }

    validates :code, presence: { length: { within: 1..10 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    validates :length_in_meters, length: { maximum: 12 }
    validates :partecipants, length: { maximum: 5 }
    validates :phases, length: { maximum: 5 }
    validates :phase_length_in_meters, length: { maximum: 8 }

    validates :style_order, presence: { length: { within: 1..3, allow_nil: false } },
                            numericality: true

    # TODO: remove unneeded
    # scope :sort_by_style,       -> { order('style_order') }
    # scope :for_fin_calculation, -> { where('((length_in_meters % 50) = 0) AND (length_in_meters <= 1500)') }
    # scope :for_ironmaster,      -> { where('(not is_a_relay and length_in_meters between 50 and 1500)') }

    # Memoize all values for virtual scopes:
    all.joins(:stroke_type).order(:style_order).each do |row|
      class_eval do
        @all_eventable ||= []
        @all_eventable << row if row&.stroke_type&.eventable?
        @all_relays ||= []
        @all_relays << row if row&.relay?
        @all_individuals ||= []
        @all_individuals << row unless row&.relay?
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # "Virtual" scope. Returns an Array of all eventable row types (depends on stroke type), sorted in style order
    # rubocop:disable Style/TrivialAccessors
    def self.all_eventable
      @all_eventable
    end

    # Virtual scope: array of memoized relay-only types of event, sorted in style order
    def self.all_relays
      @all_relays
    end

    # Virtual scope: array of memoized individual-only types of event, sorted in style order
    def self.all_individuals
      @all_individuals
    end
    # rubocop:enable Style/TrivialAccessors
    #-- ------------------------------------------------------------------------
    #++
  end
end
