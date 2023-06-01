# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Result model
  #
  # Encapsulates common behavior for Meetings & User Workshops.
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  class AbstractMeeting < ApplicationRecord
    self.abstract_class = true

    belongs_to :season
    belongs_to :edition_type
    belongs_to :timing_type
    validates_associated :season
    validates_associated :edition_type
    validates_associated :timing_type

    has_one :season_type, through: :season
    has_one :federation_type, through: :season_type

    default_scope { includes(:edition_type, :timing_type, season: [season_type: [:federation_type]]) }

    validates :code,        presence: { length: { within: 1..50 }, allow_nil: false }
    validates :header_year, presence: { length: { within: 1..9 }, allow_nil: false }
    validates :edition,     presence: { length: { maximum: 3 }, allow_nil: false }
    validates :description, presence: { length: { maximum: 100 }, allow_nil: false }

    # Sorting scopes:
    scope :by_date,   ->(dir = :asc)  { order(header_date: dir) }
    scope :by_season, ->(dir = :asc)  { joins(:season).order('seasons.begin_date': dir) }

    # Filtering scopes:
    scope :not_cancelled,   -> { where(cancelled: false) }
    scope :not_expired,     -> { not_cancelled.where('header_date >= ?', Time.zone.today) }
    scope :for_season_type, ->(season_type) { joins(:season_type).where(season_types: { id: season_type.id }) }
    scope :for_season,      ->(season) { joins(:season).where(season_id: season.id) }
    scope :for_code,        ->(code) { where(code: code) }
    #-- -----------------------------------------------------------------------
    #++

    # Returns just the verbose edition label based on the current edition value & type.
    # Returns a safe empty string otherwise.
    #
    # rubocop:disable Metrics/CyclomaticComplexity
    def edition_label
      return "#{edition}°" if edition.to_i.positive? && (edition_type.seasonal? || edition_type.ordinal?)
      return edition.to_i.to_roman if edition.to_i.positive? && edition_type.roman?
      return header_year.to_s.split('/')&.first if edition_type.yearly?

      ''
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Meeting name stripped of any edition label.
    #
    # == Params:
    # - <tt>meeting_name</tt>: the meeting name to be processed;
    #   defaults to +description+.
    #
    # == Returns:
    # the Meeting name as a +String+, stripped of any edition label.
    #
    def name_without_edition(meeting_name = description)
      _edition, result, _edition_type_id = GogglesDb::Normalizers::CodedName.edition_split_from(meeting_name)
      # Remove also the federation name from the description:
      result.gsub(/\b#{federation_type.short_name}\b/i, '').strip
    end

    # Meeting name prefixed or appended with proper edition label, depending on edition type.
    #
    # == Params:
    # - <tt>meeting_name</tt>: the meeting name to be processed;
    #   defaults to +description+.
    #
    # == Returns:
    # the Meeting name as a +String+, composed with the actual displayable edition label.
    #
    def name_with_edition(meeting_name = description)
      # Strip also the result to avoid zero edition numbers (when not properly set):
      return "#{edition_label} #{name_without_edition(meeting_name)} #{header_year}".strip if edition_type.seasonal?
      return "#{edition_label} #{name_without_edition(meeting_name)}".strip if edition_type.ordinal? || edition_type.roman?
      return "#{name_without_edition(meeting_name)} #{header_year}" if edition_type.yearly?

      meeting_name # (No edition type at all)
    end

    # Returns the shortest possible name for this meeting as a String.
    # Assumes the most significant part of the name is the ending (name, city name, ...)
    #
    # == Params:
    # - <tt>meeting_name</tt>: the meeting name to be processed;
    #   defaults to +description+.
    #
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def condensed_name(meeting_name = description)
      tokens = split_description_in_tokens(name_without_edition(meeting_name))
      # Fallback to using the notes if we have them and the splitting above does not yield tokens:
      tokens = split_description_in_tokens(notes) if tokens.blank? && notes.present?
      # Remove spaces, split in shorter tokens, delete blanks and take just the first 3:
      tokens = tokens&.to_s&.strip&.split(/\s|,/)&.reject(&:blank?)
      tokens.is_a?(Array) ? tokens[0..3]&.join(' ') : tokens.to_s
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    #++

    # Returns +true+ if this abstract meeting has either been cancelled or closed for due time.
    def expired?
      cancelled || header_date < Time.zone.today
    end
    #-- ------------------------------------------------------------------------

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'edition_label' => edition_label,
        'meeting_date' => decorate.meeting_date
      )
    end

    # Override: include the "minimum required" hash of attributes & associations.
    #
    # def minimal_attributes(locale = I18n.locale)
    #   super(locale).merge(
    #     'display_label' => decorate.display_label(locale),
    #     'short_label' => decorate.short_label(locale),
    #     'edition_label' => edition_label,

    #     'season' => season.minimal_attributes,
    #     'edition_type' => edition_type.lookup_attributes,
    #     'timing_type' => timing_type.lookup_attributes,
    #     'season_type' => season_type.minimal_attributes,
    #     'federation_type' => federation_type.minimal_attributes
    #   )
    # end
    #-- ------------------------------------------------------------------------
    #++

    private

    # Splits any specified meeting_description using common leading names to get just the most relevant part.
    # Assumes description is in Italian. Returns an empty string in the worst case scenario.
    def split_description_in_tokens(meeting_description)
      meeting_description.split(/trofeo|meeting|collegial.|workshop|campionat.|raduno/i).last || ''
    end
  end
end
