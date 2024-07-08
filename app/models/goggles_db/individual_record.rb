# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::IndividualRecord
  #
  # - version:  7-0.7.10
  # - author:   Steve A.
  #
  class IndividualRecord < ApplicationRecord
    self.table_name = 'individual_records'

    include TimingManageable

    belongs_to :swimmer
    belongs_to :team
    validates_associated :swimmer
    validates_associated :team

    belongs_to :pool_type
    belongs_to :event_type
    belongs_to :category_type
    belongs_to :gender_type
    belongs_to :season
    belongs_to :federation_type
    belongs_to :record_type

    belongs_to :meeting_individual_result, optional: true

    validates_associated :pool_type
    validates_associated :event_type
    validates_associated :category_type
    validates_associated :gender_type
    validates_associated :season
    validates_associated :federation_type
    validates_associated :record_type

    validates :minutes,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    has_one :season_type, through: :season

    default_scope do
      includes(
        :swimmer, :team,
        :pool_type, :event_type, :gender_type, :season, :season_type, :federation_type,
        :record_type
      )
    end

    delegate :first_name, :last_name, :complete_name, :year_of_birth, to: :swimmer, prefix: true
    delegate :name, :editable_name, to: :team, prefix: true
    delegate :length_in_meters, to: :event_type, prefix: false

    # Sorting scopes:
    scope :by_timing, lambda { |dir = :asc|
      order(
        Arel.sql('minutes * 6000 + seconds * 100 + hundredths') => dir.to_s.downcase.to_sym
        # Using an all in one computed column with Arel for ordering is about the same order of speed
        # than using 3 separate as (minutes: :desc, seconds: :desc, hundredths: :desc), but
        # yields slightly faster results a bit more often. (Tested with benchmarks on real data)
      )
    }

    # Filtering scopes:
    scope :for_pool_type,  ->(pool_type)  { joins(:pool_type).where('pool_types.id': pool_type.id) }
    scope :for_event_type, ->(event_type) { joins(:event_type).where(event_type_id: event_type.id) }
    scope :for_season,     ->(season)     { joins(:season).where(season_id: season.id) }
    scope :for_swimmer,    ->(swimmer)    { joins(:swimmer).where(swimmer_id: swimmer.id) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[swimmer team record_type pool_type event_type category_type gender_type season season_type federation_type]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'timing' => to_timing.to_s,
        'swimmer_name' => swimmer.complete_name,
        'swimmer_label' => swimmer.decorate.display_label(locale),
        'team_name' => team.editable_name,
        'team_label' => team.decorate.display_label,
        'event_label' => event_type.label(locale),
        'category_label' => category_type.decorate.short_label,
        'category_code' => category_type.code,
        'gender_code' => gender_type.code
      )
    end

    # Returns a commodity Hash summarizing the associated Swimmer.
    def swimmer_attributes
      {
        'id' => swimmer_id,
        'complete_name' => swimmer&.complete_name,
        'last_name' => swimmer&.last_name,
        'first_name' => swimmer&.first_name,
        'year_of_birth' => swimmer&.year_of_birth,
        'year_guessed' => swimmer&.year_guessed
      }
    end
  end
end
