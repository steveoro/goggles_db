# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingEventReservation model
  #
  #   - version:  7.035
  #   - author:   Steve A.
  #
  class MeetingEventReservation < ApplicationRecord
    self.table_name = 'meeting_event_reservations'

    belongs_to :meeting
    belongs_to :meeting_event
    belongs_to :badge
    belongs_to :team
    belongs_to :swimmer
    belongs_to :user

    validates_associated :meeting
    validates_associated :meeting_event
    validates_associated :badge
    validates_associated :team
    validates_associated :swimmer
    validates_associated :user

    has_one :season,          through: :meeting
    has_one :season_type,     through: :meeting
    has_one :event_type,      through: :meeting_event
    has_one :meeting_session, through: :meeting_event
    has_one :category_type,   through: :badge
    has_one :gender_type,     through: :swimmer

    validates :accepted, inclusion: { in: [true, false] }

    # Filtering scopes:
    scope :accepted, -> { where(accepted: true) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => meeting.id,
        'code' => meeting.code,
        'header_year' => meeting.header_year,
        'edition_label' => meeting.edition_label
      }
    end

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      attributes.merge(
        'meeting' => meeting_attributes,
        'meeting_event' => meeting_event.attributes,
        'event_type' => event_type.attributes,
        'category_type' => category_type.attributes,
        'gender_type' => gender_type.attributes,
        'badge' => badge.attributes,
        'team' => team.attributes,
        'swimmer' => swimmer.attributes,
        'user' => user.attributes
      ).to_json(options)
    end
  end
end
