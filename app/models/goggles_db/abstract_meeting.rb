# frozen_string_literal: true

module GogglesDb
  #
  # = Abstract Result model
  #
  # Encapsulates common behavior for Meetings & User Workshops.
  #
  #   - version:  7.02.18
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

    validates :code,        presence: { length: { within: 1..50 }, allow_nil: false }
    validates :header_year, presence: { length: { within: 1..9 }, allow_nil: false }
    validates :edition,     presence: { length: { maximum: 3 }, allow_nil: false }
    validates :description, presence: { length: { maximum: 100 }, allow_nil: false }

    # Sorting scopes:

    # Filtering scopes:
    #-- -----------------------------------------------------------------------
    #++

    # Returns the verbose edition label based on the current edition value & type.
    # Returns a safe empty string otherwise.
    #
    def edition_label
      return edition.to_s if edition_type.ordinal?

      return edition.to_i.to_roman if edition_type.roman?

      return header_year if edition_type.seasonal? || edition_type.yearly?

      ''
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the "minimum required" hash of attributes & associations.
    #
    def minimal_attributes
      super.merge(
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
