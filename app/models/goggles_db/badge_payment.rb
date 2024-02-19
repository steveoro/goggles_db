# frozen_string_literal: true

module GogglesDb
  #
  # = Badge payment model
  #
  #   - version:  7-0.6.30
  #   - authors:  Leega, Steve A.
  #
  class BadgePayment < ApplicationRecord
    self.table_name = 'badge_payments'

    belongs_to :badge
    validates_associated :badge

    has_one  :swimmer, through: :badge
    has_one  :season,  through: :badge
    has_one  :team,    through: :badge

    has_one  :team_affiliation, through: :badge
    has_one  :category_type, through: :badge
    has_one  :entry_time_type, through: :badge
    has_one  :gender_type, through: :swimmer

    validates :payment_date, presence: { allow_nil: false }
    validates :amount, presence: { allow_nil: false }

    default_scope { includes(:badge, :swimmer, :season, :team) }

    # Sorting scopes:
    scope :by_date, ->(dir = :asc) { order('badge_payments.payment_date': dir) }

    # Filtering scopes:
    scope :for_badge,   ->(badge)   { where(badge_id: badge.id) }
    scope :for_badges,  ->(badges)  { where(badge_id: badges.map(&:id).uniq) }
    scope :for_swimmer, ->(swimmer) { joins(:swimmer).where('swimmers.id': swimmer.id) }
    scope :for_team,    ->(team)    { joins(:team).where('teams.id': team.id) }

    delegate :complete_name, to: :swimmer, prefix: true
    #-- ------------------------------------------------------------------------
    #++
  end
end
