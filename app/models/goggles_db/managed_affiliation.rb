# frozen_string_literal: true

module GogglesDb
  #
  # = ManagedAffiliation model
  #
  # (previously known as "TeamManager")
  #
  #   - version:  7-0.3.33
  #   - author:   Steve A.
  #
  class ManagedAffiliation < ApplicationRecord
    self.table_name = 'managed_affiliations'

    belongs_to :manager, class_name: 'GogglesDb::User', foreign_key: 'user_id'
    validates_associated :manager

    belongs_to :team_affiliation
    validates_associated :team_affiliation

    has_one  :team, through: :team_affiliation
    has_one  :season, through: :team_affiliation

    delegate :name, to: :manager, prefix: true
    #-- -----------------------------------------------------------------------
    #++

    # Override: include the minimum required 1st-level attributes & associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Override: includes all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(minimal_associations).to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    def minimal_associations
      {
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'manager' => manager.minimal_attributes,
        'team_affiliation' => team_affiliation.minimal_attributes
      }
    end
  end
end
