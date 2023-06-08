# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingProgram model
  #
  #   - version:  7-0.5.10
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

    belongs_to :standard_timing, optional: true

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

    # Allow laps to be retrieved even if they are added before the final result is available:
    has_many :laps

    validates :event_order, presence: { length: { within: 1..3, allow_nil: false } }

    delegate :scheduled_date, to: :meeting_session, prefix: false, allow_nil: false
    delegate :relay?,         to: :meeting_event,   prefix: false, allow_nil: false
    #-- ------------------------------------------------------------------------
    #   Sorting scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Sort by EventType(code, event_order)
    # == Params
    # - dir: :asc|:desc
    def self.by_event_type(dir = :asc)
      joins(:event_type)
        .includes(:event_type)
        .order('event_types.code': dir, 'meeting_programs.event_order': dir)
    end

    # Sort by CategoryType(code, event_order)
    # == Params
    # - dir: :asc|:desc
    def self.by_category_type(dir = :asc)
      joins(:category_type)
        .includes(:category_type)
        .order('category_types.code': dir, 'meeting_programs.event_order': dir)
    end

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    scope :relays,      -> { joins(:event_type).includes(:event_type).where('event_types.relay': true) }
    scope :individuals, -> { joins(:event_type).includes(:event_type).where('event_types.relay': false) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[pool_type event_type category_type gender_type stroke_type]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[meeting_individual_results meeting_relay_results]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'event_label' => event_type.label(locale),
        'category_label' => category_type.decorate.short_label,
        'category_code' => category_type.code,
        'gender_code' => gender_type.code,
        'pool_code' => pool_type.code
      )
    end
  end
end
