# frozen_string_literal: true

module GogglesDb
  #
  # = Calendar model
  #
  # Legacy name: "FINCalendar"
  #
  #   - version:  7.0.3.45
  #   - author:   Steve A.
  #
  class Calendar < ApplicationRecord
    self.table_name = 'calendars'

    belongs_to :season
    belongs_to :meeting, optional: true
    has_one :season_type, through: :season

    validates_associated :season

    validates :meeting_code, presence: { allow_nil: false }
    validates :scheduled_date, presence: { allow_nil: false }
    validates :year, presence: { allow_nil: false }
    validates :month, presence: { allow_nil: false }
    # NOTE: on some occasions, meeting_name may be nil; the decorator will return a '?'.

    default_scope { includes(season: [:season_type]) }

    # Sorting scopes:
    scope :by_date,   ->(dir = :asc)  { order(scheduled_date: dir) }
    scope :by_season, ->(dir = :asc)  { joins(:season).order('seasons.begin_date': dir) }

    # Filtering scopes:
    scope :for_season_type, ->(season_type) { joins(:season_type).where(season_types: { id: season_type.id }) }
    scope :for_season,      ->(season) { joins(:season).where(season_id: season.id) }
    scope :for_code,        ->(code) { where(meeting_code: code) }
    scope :not_cancelled,   -> { where(cancelled: false) }

    scope :still_open_at, lambda { |date = Time.zone.today|
      ids = where(cancelled: false).joins(:meeting).includes(:meeting)
                                   .where('(meetings.cancelled = false) AND (meetings.header_date > ?)', date)
                                   .pluck(:id)
      ids << where(cancelled: false, meeting: nil).pluck(:id)
      ids.uniq!
      where(id: ids).by_date(:desc)
    }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the minimum required 1st-level associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Override: includes all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'meeting_date' => decorate.meeting_date,
        'season' => season.minimal_attributes,
        'meeting' => meeting&.minimal_attributes
      ).to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    #
    # === Note:
    # Typically these should be a subset of the (full) associations enlisted
    # inside #to_json.
    # The rationale here is to select just the bare amount of "leaf entities"
    # in the hierachy tree so that these won't be included more than once in
    # any #minimal_attributes output invoked from a higher level or parent entity.
    #
    # Example:
    # #to_json or #attributes of team_affilition.badges vs single badge output.
    def minimal_associations
      {
        'season' => season.minimal_attributes,
        'meeting' => meeting&.minimal_attributes
      }
    end
  end
end
