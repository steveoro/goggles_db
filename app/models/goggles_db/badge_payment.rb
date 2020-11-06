# frozen_string_literal: true

module GogglesDb
  #
  # = Badge payment model
  #
  #   - version:  7.030
  #   - authors:  Leega, Steve A.
  #
  class BadgePayment < ApplicationRecord
    self.table_name = 'badge_payments'

    belongs_to :badge
    validates_associated :badge

    has_one  :swimmer, through: :badge
    has_one  :season,  through: :badge
    has_one  :team,    through: :badge

    validates :payment_date, presence: { allow_nil: false }
    validates :amount, presence: { allow_nil: false }

    # Sorting scopes:
    scope :by_date, ->(dir = 'ASC') { order(dir == 'ASC' ? 'badge_payments.payment_date ASC' : 'badge_payments.payment_date DESC') }

    # Filtering scopes:
    scope :for_badge,   ->(badge)   { where(badge_id: badge.id) }
    scope :for_badges,  ->(badges)  { where(badge_id: badges.map(&:id).uniq) }
    scope :for_swimmer, ->(swimmer) { joins(:swimmer).where("swimmers.id = #{swimmer.id}") }
    scope :for_team,    ->(team)    { joins(:team).where("teams.id = #{team.id}") }
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'badge' => badge.attributes,
        'swimmer' => swimmer.attributes,
        'season' => season.attributes,
        'team' => team.attributes
      ).to_json(options)
    end
  end
end
