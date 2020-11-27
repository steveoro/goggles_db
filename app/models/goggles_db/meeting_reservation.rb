# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingReservation model
  #
  #   - version:  7.035
  #   - author:   Steve A.
  #
  class MeetingReservation < ApplicationRecord
    self.table_name = 'meeting_reservations'

    belongs_to :meeting
    belongs_to :badge
    belongs_to :team
    belongs_to :swimmer
    belongs_to :user

    validates_associated :meeting
    validates_associated :badge
    validates_associated :team
    validates_associated :swimmer
    validates_associated :user

    has_one  :season,           through: :meeting
    has_one  :season_type,      through: :meeting
    has_many :meeting_sessions, through: :meeting

    validates :not_coming, inclusion: { in: [true, false] }
    validates :confirmed, inclusion: { in: [true, false] }

    # Filtering scopes:
    scope :coming, -> { where(not_coming: false) }
    #-- ------------------------------------------------------------------------
    #++

    # Commodity helper that returns +true+ if this reservation row hasn't been cancelled
    # directly by the athlete.
    #
    # This won't guarantee that this registration state can be considered "final" until
    # the offical enrollment end-date for the Meeting has been reached - meaning that, before
    # the registration end-date hits, the athlete could always change ideas or skip the whole
    # Meeting by flagging the registration as void ('not_coming').
    #
    # (Reservations are prepared by the Team manager but can be manually voided afterwards by each
    #  enrolled athlete until the registration period ends.
    #  Any athlete can manually confirm her/his registration by editing the 'confirmed?' flag.)
    def coming?
      !not_coming?
    end

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
        'badge' => badge.attributes,
        'team' => team.attributes,
        'swimmer' => swimmer.attributes,
        'user' => user.attributes
      ).to_json(options)
    end
  end
end
