# frozen_string_literal: true

module GogglesDb
  #
  # = UserResult model
  #
  #   - version:  7.3.10
  #   - author:   Steve A.
  #
  # User results are swimming event timings:
  #
  # - recorded directly by users;
  # - achieved by different swimmers;
  # - achieved in different pools;
  # - relating swimmers to the same workshop event, even if belonging to different teams.
  #
  # User results can be used together with UserWorkshops and UserLaps
  # to create internal "Meetings" even when not attending directly to
  # a specific venue (although you can have a default pool & team).
  #
  class UserResult < AbstractResult
    self.table_name = 'user_results'

    belongs_to :user_workshop
    belongs_to :user
    belongs_to :swimmer
    belongs_to :category_type
    belongs_to :pool_type
    belongs_to :event_type
    belongs_to :swimming_pool

    validates_associated :user_workshop
    validates_associated :user
    validates_associated :swimmer
    validates_associated :category_type
    validates_associated :pool_type
    validates_associated :event_type
    validates_associated :swimming_pool

    has_one :gender_type, through: :swimmer
    has_one :stroke_type, through: :event_type

    belongs_to :disqualification_code_type, optional: true

    has_one :season,      through: :user_workshop
    has_one :season_type, through: :season

    has_many :user_laps, -> { order('user_laps.length_in_meters') }, dependent: :delete_all
    alias laps user_laps # (new, old)

    # Sorting scopes:
    scope :by_date, ->(dir = :asc) { joins(:user_workshop).order('user_workshops.header_date': dir) }

    # Filtering scopes:
    scope :for_workshop_code, ->(workshop) { joins(:user_workshop).where('user_workshops.code': workshop&.code) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this result can be scored into the overall ranking.
    def valid_for_ranking?
      !disqualified?
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      attributes.merge(
        'timing' => to_timing.to_s,
        'user_workshop' => meeting_attributes,
        'pool_type' => pool_type.lookup_attributes,
        'event_type' => event_type.lookup_attributes,
        'category_type' => category_type.minimal_attributes,
        'gender_type' => gender_type.lookup_attributes,
        'stroke_type' => stroke_type.lookup_attributes,
        'laps' => laps&.map(&:minimal_attributes) # (Optional)
      ).merge(
        minimal_associations
      ).to_json(options)
    end

    # AbstractLap overrides:
    alias_attribute :parent_meeting, :user_workshop # (old, new)
    alias user_workshop_attributes meeting_attributes # (new, old)

    private

    # Returns the "minimum required" hash of associations.
    #
    # Typical use for this is as helper called from within the #to_json definition
    # of a parent entity via a #minimal_attributes call.
    def minimal_associations
      super.merge(
        'swimming_pool' => swimming_pool&.minimal_attributes
      )
    end
  end
end
