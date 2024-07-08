# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingRelayReservation model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  # Same properties and methods as MeetingEventReservation, with just a different table name
  # (minus the timing fields).
  #
  # Relay reservations are individual Meeting Relay registrations, added personally by each athlete
  # to signal availability for relay call by the Team Manager.
  #
  class MeetingRelayReservation < ApplicationRecord
    self.table_name = 'meeting_relay_reservations'

    belongs_to :meeting_reservation
    belongs_to :meeting
    belongs_to :meeting_event
    belongs_to :badge
    belongs_to :team
    belongs_to :swimmer

    validates_associated :meeting_reservation
    validates_associated :meeting
    validates_associated :meeting_event
    validates_associated :badge
    validates_associated :team
    validates_associated :swimmer

    has_one :season,          through: :meeting
    has_one :season_type,     through: :meeting
    has_one :event_type,      through: :meeting_event
    has_one :meeting_session, through: :meeting_event
    has_one :category_type,   through: :badge
    has_one :gender_type,     through: :swimmer

    default_scope do
      includes(
        :meeting_reservation, :meeting, :meeting_event,
        :badge, :team, :swimmer,
        :meeting_session, :event_type, :category_type, :gender_type,
        :season, :season_type
      )
    end

    validates :accepted, inclusion: { in: [true, false] }

    # Filtering scopes:
    scope :accepted, -> { where(accepted: true) }
    #-- ------------------------------------------------------------------------
    #++

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'swimmer_name' => swimmer.complete_name,
        'swimmer_label' => swimmer.decorate.display_label(locale),
        'team_name' => team.editable_name,
        'team_label' => team.decorate.display_label,
        'event_label' => event_type.label(locale),
        'category_label' => category_type.decorate.short_label,
        'category_code' => category_type.code,
        'gender_code' => gender_type.code
      )
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
  end
end
