# frozen_string_literal: true

module GogglesDb
  #
  # = Lap model
  #
  #   - version:  7.030
  #   - author:   Steve A.
  #
  class Lap < ApplicationRecord
    self.table_name = 'laps'

    # TODO
    # belongs_to :meeting_program
    # belongs_to :team
    # validates_associated :meeting_program
    # validates_associated :team

    # belongs_to :meeting_entry
    # belongs_to :meeting_individual_result

    # has_one :meeting,         through: :meeting_program
    # has_one :event_type,      through: :meeting_program
    # has_one :pool_type,       through: :meeting_program
    # #  has_one :badge,           through: :meeting_entry

    # validates :minutes, presence: true
    # validates :minutes, length: { within: 1..3, allow_nil: false }
    # validates :minutes, numericality: true
    # validates :seconds, presence: true
    # validates :seconds, length: { within: 1..2, allow_nil: false }
    # validates :seconds, numericality: true
    # validates :hundreds, presence: true
    # validates :hundreds, length: { within: 1..2, allow_nil: false }
    # validates :hundreds, numericality: true

    validates :length_in_meters, presence: { length: { within: 1..5, allow_nil: false } },
                                 numericality: true

    # # validates_presence_of     :reaction_time
    # # validates_numericality_of :reaction_time
    # # validates_presence_of     :stroke_cycles
    # # validates_length_of       :stroke_cycles, within: 1..3, allow_nil: true
    # # validates_numericality_of :stroke_cycles
    # # validates_presence_of     :breath_number
    # # validates_length_of       :breath_number, within: 1..3, allow_nil: true
    # # validates_numericality_of :breath_number
    # # validates_presence_of     :position
    # # validates_length_of       :position, within: 1..4, allow_nil: true
    # # validates_numericality_of :position
    # # validates_presence_of     :not_swam_kick_number
    # # validates_length_of       :not_swam_kick_number, within: 1..3, allow_nil: true
    # # validates_numericality_of :not_swam_kick_number
    # # validates_presence_of     :not_swam_part_seconds
    # # validates_length_of       :not_swam_part_seconds, within: 1..2, allow_nil: true
    # # validates_numericality_of :not_swam_part_seconds
    # # validates_presence_of     :not_swam_part_hundreds
    # # validates_length_of       :not_swam_part_hundreds, within: 1..2, allow_nil: true
    # # validates_numericality_of :not_swam_part_hundreds

    # scope :sort_by_user,       ->(dir) { order("users.name #{dir}, swimmer_id #{dir}") }
    # scope :sort_by_distance,   -> { joins(:passage_type).order('passage_types.length_in_meters') }

    # scope :for_event_type,     ->(event_type) { joins(:event_type).where(['event_types.id = ?', event_type.id]) }
  end
end
