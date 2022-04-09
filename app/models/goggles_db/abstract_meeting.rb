# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Result model
  #
  # Encapsulates common behavior for Meetings & User Workshops.
  #
  #   - version:  7-0.3.45
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

    default_scope { includes(:edition_type, :timing_type, season: [:season_type]) }

    validates :code,        presence: { length: { within: 1..50 }, allow_nil: false }
    validates :header_year, presence: { length: { within: 1..9 }, allow_nil: false }
    validates :edition,     presence: { length: { maximum: 3 }, allow_nil: false }
    validates :description, presence: { length: { maximum: 100 }, allow_nil: false }

    # Sorting scopes:
    scope :by_date,   ->(dir = :asc)  { order(header_date: dir) }
    scope :by_season, ->(dir = :asc)  { joins(:season).order('seasons.begin_date': dir) }

    # Filtering scopes:
    scope :not_cancelled,   -> { where(cancelled: false) }
    scope :for_season_type, ->(season_type) { joins(:season_type).where(season_types: { id: season_type.id }) }
    scope :for_season,      ->(season) { joins(:season).where(season_id: season.id) }
    scope :for_code,        ->(code) { where(code: code) }
    #-- -----------------------------------------------------------------------
    #++

    # Returns just the verbose edition label based on the current edition value & type.
    # Returns a safe empty string otherwise.
    #
    def edition_label
      return "#{edition}°" if edition_type.ordinal?
      return edition.to_i.to_roman if edition_type.roman?
      return header_year if edition_type.seasonal? || edition_type.yearly?

      ''
    end

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
      tokens = if edition_label.present? && meeting_name.starts_with?(/#{edition_label}\s|#{edition}°/)
                 condensed_name(meeting_name).split(/#{edition_label}\s|#{edition}°/)
               elsif meeting_name.starts_with?(/#{edition}°/)
                 condensed_name(meeting_name).split(/#{edition}°/)
               else
                 [condensed_name(meeting_name)]
               end
      tokens.reject(&:empty?)
            .last.strip
            .split(/(#{header_year})/)
            .reject(&:empty?)
            .first.strip
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
      return "#{edition_label} #{name_without_edition(meeting_name)}" if edition_type.ordinal? || edition_type.roman?
      return "#{name_without_edition(meeting_name)} #{header_year}" if edition_type.seasonal? || edition_type.yearly?

      meeting_name
    end

    # Returns the shortest possible name for this meeting as a String.
    # Assumes the most significant part of the name is the ending (name, city name, ...)
    #
    # == Params:
    # - <tt>meeting_name</tt>: the meeting name to be processed;
    #   defaults to +description+.
    #
    def condensed_name(meeting_name = description)
      # Remove spaces, split in tokens, delete empty tokens and take just the first 3:
      meeting_name.split(/trofeo|meeting|collegiale|workshop|campionato|raduno/i)
                  .last
                  .strip.split(/\s|,/)
                  .reject(&:empty?)[0..3]
                  .join(' ')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the "minimum required" hash of attributes & associations.
    #
    def minimal_attributes
      super.merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'edition_label' => edition_label,
        'season' => season.minimal_attributes,
        'edition_type' => edition_type.lookup_attributes,
        'timing_type' => timing_type.lookup_attributes,
        'season_type' => season_type.minimal_attributes,
        'federation_type' => federation_type.minimal_attributes
      )
    end
  end
end
