# frozen_string_literal: true

module GogglesDb
  #
  # = UserResult model
  #
  #   - version:  7-0.7.24
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
    belongs_to :category_type
    belongs_to :pool_type
    belongs_to :event_type
    belongs_to :swimming_pool

    validates_associated :user_workshop
    validates_associated :user
    validates_associated :category_type
    validates_associated :pool_type
    validates_associated :event_type
    validates_associated :swimming_pool

    has_one :gender_type, through: :swimmer
    has_one :stroke_type, through: :event_type

    belongs_to :disqualification_code_type, optional: true
    belongs_to :standard_timing, optional: true

    has_one :season,      through: :user_workshop
    has_one :season_type, through: :season

    has_many :user_laps, -> { order('user_laps.length_in_meters') }, dependent: :delete_all
    alias laps user_laps # (new, old)

    default_scope do
      includes(
        :user_workshop, :user, :swimmer, :gender_type,
        :category_type, :event_type, :stroke_type,
        :swimming_pool, :pool_type,
        :season, :season_type
      )
    end

    # Sorting scopes:
    scope :by_date, ->(dir = :asc) { joins(:user_workshop).order('user_workshops.header_date': dir) }

    # Filtering scopes:
    scope :for_workshop_code, ->(workshop) { joins(:user_workshop).where('user_workshops.code': workshop&.code) }
    #-- ------------------------------------------------------------------------
    #++

    # AbstractResult overrides:
    alias_attribute :parent_meeting, :user_workshop # (old, new)

    alias user_workshop_attributes meeting_attributes # (new, old)
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      super + %w[user_workshop swimming_pool pool_type event_type category_type stroke_type]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'event_label' => event_type.label(locale),
        'category_label' => category_type.decorate.short_label,
        'category_code' => category_type.code,
        'gender_code' => gender_type.code
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this result can be scored into the overall ranking.
    def valid_for_ranking?
      !disqualified? && positive?
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
