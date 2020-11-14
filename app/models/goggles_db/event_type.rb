# frozen_string_literal: true

module GogglesDb
  #
  # = EventType model
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class EventType < ApplicationLookupEntity
    self.table_name = 'event_types'

    belongs_to :stroke_type
    validates :stroke_type, presence: true
    validates_associated :stroke_type

    validates :code, presence: { length: { within: 1..10 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    validates :length_in_meters, length: { maximum: 12 }
    validates :partecipants, length: { maximum: 5 }
    validates :phases, length: { maximum: 5 }
    validates :phase_length_in_meters, length: { maximum: 8 }

    validates :style_order, presence: { length: { within: 1..3, allow_nil: false } },
                            numericality: true

    # has_many :meeting_events
    # has_many :meeting_sessions, through: :meeting_events
    # has_many :meetings,         through: :meeting_sessions
    # has_many :seasons,          through: :meetings
    # has_many :season_types,     through: :seasons
    #
    # has_many :events_by_pool_types
    # has_many :pool_types,       through: :events_by_pool_types
    #
    # scope :sort_by_style,       -> { order('style_order') }
    # scope :for_fin_calculation, -> { where('((length_in_meters % 50) = 0) AND (length_in_meters <= 1500)') }
    # scope :for_ironmaster,      -> { where('(not is_a_relay and length_in_meters between 50 and 1500)') }

    # TODO: Needs a working full-chain relation with a Meeting to work:
    # scope :for_season_type, ->(season_type) { joins(:season_types).where(['season_types.id = ?', season_type.id]) }
    # scope :for_season,      ->(season_id)   { joins(:seasons).where(['season_id = ?', season_id]) }

    alias_attribute :relay?, :is_a_relay

    # Memoize all values for virtual scopes:
    all.joins(:stroke_type).includes(:stroke_type).order(:style_order).each do |row|
      class_eval do
        @only_relays ||= []
        @only_relays << row if row&.relay?
        @only_individuals ||= []
        @only_individuals << row unless row&.relay?
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Virtual scope: array of memoized relay-only types of event, sorted in style order
    # rubocop:disable Style/TrivialAccessors
    def self.only_relays
      @only_relays
    end

    # Virtual scope: array of memoized individual-only types of event, sorted in style order
    def self.only_individuals
      @only_individuals
    end
    # rubocop:enable Style/TrivialAccessors
    #-- ------------------------------------------------------------------------
    #++
  end
end
