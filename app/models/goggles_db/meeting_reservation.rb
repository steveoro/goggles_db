# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingReservation model
  #
  #   - version:  7-0.3.33
  #   - author:   Steve A.
  #
  # Reservations are individual Meeting registrations, associated just to a specific
  # Meeting and can be added as soon as the Meeting is defined.
  # (Meeting sessions & events does not need to be there yet)
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

    has_many :meeting_event_reservations, dependent: :delete_all
    has_many :meeting_relay_reservations, dependent: :delete_all

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
    #-- ------------------------------------------------------------------------
    #++

    # Override: include the "minimum required" hash of attributes & associations.
    #
    def minimal_attributes
      super.merge(minimal_associations)
    end

    # Returns a commodity Hash wrapping the essential data that summarizes the Meeting
    # associated to this row.
    def meeting_attributes
      {
        'id' => meeting.id,
        'code' => meeting.code,
        'header_year' => meeting.header_year,
        'display_label' => meeting.decorate.display_label,
        'short_label' => meeting.decorate.short_label,
        'edition_label' => meeting.edition_label
      }
    end

    # Override: includes most relevant data for its 1st-level associations
    def to_json(options = nil)
      base = attributes.merge('meeting' => meeting_attributes, 'user' => user.minimal_attributes)
                       .merge(minimal_associations)
      # A Meeting reservation can have both type of children:
      base.merge!('meeting_event_reservations' => meeting_event_reservations.map(&:minimal_attributes)) if meeting_event_reservations.count.positive?
      base.merge!('meeting_relay_reservations' => meeting_relay_reservations.map(&:minimal_attributes)) if meeting_relay_reservations.count.positive?
      base.to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    def minimal_associations
      {
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'badge' => badge.minimal_attributes,
        # (^^ This includes: gender_type, category_type & entry_time_type)
        'team' => team.minimal_attributes,
        'swimmer' => swimmer.minimal_attributes
      }
    end
  end
end
