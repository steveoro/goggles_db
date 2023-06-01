# frozen_string_literal: true

module GogglesDb
  #
  # = ManagedAffiliation model
  #
  # (formerly known as "TeamManager")
  #
  #   - version:  7-0.5.10
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

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label
      )
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
