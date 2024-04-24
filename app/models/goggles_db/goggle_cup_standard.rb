# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::GoggleCupStandard
  #
  # - version:  7-0.7.10
  # - author:   Steve A.
  #
  class GoggleCupStandard < ApplicationRecord
    self.table_name = 'goggle_cup_standards'

    include TimingManageable

    belongs_to :swimmer
    belongs_to :goggle_cup
    belongs_to :pool_type
    belongs_to :event_type

    validates_associated :swimmer
    validates_associated :goggle_cup
    validates_associated :pool_type
    validates_associated :event_type

    validates :minutes,  presence: { length: { within: 1..3, allow_nil: false } }, numericality: true
    validates :seconds,  presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :hundredths, presence: { length: { within: 1..2, allow_nil: false } }, numericality: true
    validates :reaction_time, presence: true, numericality: true

    default_scope { includes(:swimmer, :goggle_cup, :pool_type, :event_type) }

    delegate :first_name, :last_name, :complete_name, :year_of_birth, to: :swimmer, prefix: true
    delegate :name, :editable_name, to: :team, prefix: true

    delegate :team, to: :goggle_cup, prefix: false
    delegate :length_in_meters, to: :event_type, prefix: false
    #-- ------------------------------------------------------------------------
    #++

    # TODO
  end
end
