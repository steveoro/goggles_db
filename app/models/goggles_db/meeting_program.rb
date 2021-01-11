# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingProgram model
  #
  #   - version:  7.061
  #   - author:   Steve A.
  #
  class MeetingProgram < ApplicationRecord
    self.table_name = 'meeting_programs'

    belongs_to :meeting_event
    belongs_to :pool_type # Redundant/commodity association with pool_types
    belongs_to :category_type
    belongs_to :gender_type
    validates_associated :meeting_event
    validates_associated :pool_type
    validates_associated :category_type
    validates_associated :gender_type

    belongs_to :time_standard, optional: true

    has_one :meeting_session, through: :meeting_event
    has_one :meeting,         through: :meeting_session
    has_one :season,          through: :meeting_session
    has_one :season_type,     through: :meeting_session
    has_one :event_type,      through: :meeting_event
    has_one :stroke_type,     through: :event_type

    has_many :meeting_individual_results, dependent: :delete_all
    has_many :meeting_relay_results,      dependent: :delete_all
    has_many :meeting_relay_swimmers,     through: :meeting_relay_results
    has_many :meeting_entries, dependent: :delete_all

    # Laps are usually added before the actual final result is available:
    has_many :laps, -> { joins(:laps).order('laps.length_in_meters') }

    validates :event_order, presence: { length: { within: 1..3, allow_nil: false } }

    delegate :scheduled_date, to: :meeting_session, prefix: false, allow_nil: false
    delegate :relay?,         to: :meeting_event,   prefix: false, allow_nil: false

    # Sorting scopes:
    def self.by_event_type(dir = :asc)
      joins(:event_type)
        .includes(:event_type)
        .order('event_types.code': dir, 'meeting_programs.event_order': dir)
    end

    def self.by_category_type(dir = :asc)
      joins(:category_type)
        .includes(:category_type)
        .order('category_types.code': dir, 'meeting_programs.event_order': dir)
    end

    # Filtering scopes:
    scope :relays,      -> { joins(:event_type).includes(:event_type).where('event_types.relay': true) }
    scope :individuals, -> { joins(:event_type).includes(:event_type).where('event_types.relay': false) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the "minimum required" hash of associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Override: includes *most* of the 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      base = attributes.merge('meeting_event' => meeting_event.minimal_attributes)
                       .merge(minimal_associations)

      if relay? && meeting_relay_results.count.positive?
        base.merge!('meeting_relay_results' => meeting_relay_results.map(&:minimal_attributes))
      elsif !relay? && meeting_individual_results.count.positive?
        base.merge!('meeting_individual_results' => meeting_individual_results.map(&:minimal_attributes))
      end
      base.to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    #
    # Typical use for this is as helper method called from within the #to_json definition of a parent entity.
    # Assuming the above, usually most associations can be safely skipped avoid duplication output.
    def minimal_associations
      {
        'pool_type' => pool_type.lookup_attributes,
        'event_type' => event_type.lookup_attributes,
        'category_type' => category_type.minimal_attributes,
        'gender_type' => gender_type.lookup_attributes,
        'stroke_type' => stroke_type.lookup_attributes
      }
    end
  end
end
