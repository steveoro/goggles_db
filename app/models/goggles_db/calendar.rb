# frozen_string_literal: true

module GogglesDb
  #
  # = Calendar model
  #
  # Legacy name: "FINCalendar"
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class Calendar < ApplicationRecord
    self.table_name = 'calendars'

    belongs_to :season
    belongs_to :meeting, optional: true

    validates_associated :season

    has_one :season_type, through: :season
    has_one :edition_types, through: :season
    has_one :timing_type, through: :season
    has_one :federation_type, through: :season_type

    default_scope do
      includes(:season, :meeting, :season_type, :edition_types, :timing_type, :federation_type)
        .left_outer_joins(:meeting, :season)
    end

    # Attach PDFs or images directly to the record, if needed:
    has_one_attached :manifest_file # (use #manifest for converted text only)
    has_one_attached :results_file

    validates :meeting_code, presence: { allow_nil: false }
    validates :scheduled_date, presence: { allow_nil: false }
    validates :year, presence: { allow_nil: false }
    validates :month, presence: { allow_nil: false }
    # NOTE: on some occasions, meeting_name may be nil; the decorator will return a '?'.

    # Sorting scopes:
    scope :by_meeting, ->(dir = :asc) { joins(:meeting).includes(:meeting).order('meetings.header_date': dir) }
    scope :by_season,  ->(dir = :asc) { joins(:season).order('seasons.begin_date': dir) }

    # Filtering scopes:
    scope :for_season_type, ->(season_type) { joins(:season_type).where(season_types: { id: season_type.id }) }
    scope :for_season,      ->(season) { joins(:season).where(season_id: season.id) }
    scope :for_code,        ->(code) { where(meeting_code: code) }
    scope :not_cancelled,   -> { where(cancelled: false) }

    scope :still_open_at, lambda { |date = Time.zone.today|
      ids = where(cancelled: false).joins(:meeting)
                                   .includes(:meeting)
                                   .where('(meetings.cancelled = false) AND (meetings.header_date > ?)', date)
                                   .pluck(:id)
      ids << where(cancelled: false, meeting: nil).pluck(:id)
      ids.uniq!
      where(id: ids)
        .includes(:meeting, :season_type, :edition_types, :timing_type)
        .by_meeting(:desc)
    }
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if this row has either been cancelled or closed for due time.
    def expired?
      return true if cancelled

      meeting && (meeting.cancelled || meeting.header_date < Time.zone.today)
    end
    #-- ------------------------------------------------------------------------

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[season season_type meeting]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'meeting_date' => decorate.meeting_date
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Helper for #manifest_file.
    # Returns the attachment contents as a string by reading the attached local file;
    # returns an empty string otherwise.
    def manifest_file_contents
      return '' if manifest_file.blank?

      manifest_file.open { |file| File.read(file) }
    end

    # Helper for #results_file.
    # Returns the attachment contents as a string by reading the attached local file;
    # returns an empty string otherwise.
    def results_file_contents
      return '' if results_file.blank?

      results_file.open { |file| File.read(file) }
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
