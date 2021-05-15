# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Result model
  #
  # Encapsulates common behavior for MIRs & User Results.
  #
  #   - version:  7.02.18
  #   - author:   Steve A.
  #
  class AbstractResult < ApplicationRecord
    self.abstract_class = true

    include TimingManageable

    belongs_to :disqualification_code_type, optional: true

    validates :rank, presence: { length: { within: 1..4, allow_nil: false } },
                     numericality: true

    validates :minutes,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true

    validates :standard_points,   presence: true, numericality: true
    validates :meeting_points,    presence: true, numericality: true
    validates :reaction_time,     presence: true, numericality: true

    # Sorting scopes:
    scope :by_rank,   ->(dir = :asc) { order(disqualified: :asc, rank: dir.to_s.downcase.to_sym) }
    scope :by_timing, lambda { |dir = :asc|
      order(
        disqualified: :asc,
        Arel.sql('minutes * 6000 + seconds * 100 + hundredths') => dir.to_s.downcase.to_sym
        # Using an all in one computed column with Arel for ordering is about the same order of speed
        # than using 3 separate as (minutes: :desc, seconds: :desc, hundredths: :desc), but
        # yields slighlty faster results a bit more often. (Tested with benchmarks or real data)
      )
    }

    # Filtering scopes:
    scope :qualifications,    -> { where(disqualified: false) }
    scope :disqualifications, -> { where(disqualified: true) }

    scope :for_pool_type,   ->(pool_type)   { joins(:pool_type).where('pool_types.id': pool_type.id) }
    scope :for_event_type,  ->(event_type)  { joins(:event_type).where('event_types.id': event_type.id) }
    scope :for_gender_type, ->(gender_type) { joins(:gender_type).where('gender_types.id': gender_type.id) }
    scope :for_swimmer,     ->(swimmer)     { where(swimmer_id: swimmer.id) }
    scope :for_rank,        ->(rank_filter) { where(rank: rank_filter) }

    scope :with_rank,    -> { where('rank > 0') } # any positive rank => qualified
    scope :with_no_rank, -> { where('(rank = 0) OR (rank IS NULL)') }
    scope :with_time,    -> { where('(minutes > 0) OR (seconds > 0) OR (hundredths > 0)') }
    scope :with_no_time, -> { where(minutes: 0, seconds: 0, hundredths: 0) }
    #-- -----------------------------------------------------------------------
    #++

    # Override: include the "minimum required" hash of attributes & associations.
    #
    def minimal_attributes
      super.merge(
        'timing' => to_timing.to_s
      ).merge(minimal_associations)
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => parent_meeting&.id,
        'code' => parent_meeting&.code,
        'header_year' => parent_meeting&.header_year,
        'edition_label' => parent_meeting&.edition_label
      }
    end

    # Similarly to <tt>#meeting_attributes</tt>, this returns a commodity Hash
    # summarizing the associated Swimmer.
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

    protected

    # Generalization for the parent association with a Meeting or a UserWorkshop entity.
    # Returns either one or the other, depending on what the sibling responds to.
    #
    # ==> OVERRIDE IN SIBLINGS <==
    def parent_meeting; end

    # Returns the "minimum required" hash of associations.
    #
    # Typical use for this is as helper called from within the #to_json definition
    # of a parent entity via a #minimal_attributes call.
    def minimal_associations
      {
        'swimmer' => swimmer_attributes,
        'disqualification_code_type' => disqualification_code_type&.lookup_attributes
      }
    end
  end
end
