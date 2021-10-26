# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingRelayReservation model
  #
  #   - version:  7-0.3.33
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

    validates :accepted, inclusion: { in: [true, false] }

    # Filtering scopes:
    scope :accepted, -> { where(accepted: true) }
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
      attributes.merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'meeting' => meeting_attributes,
        'meeting_event' => meeting_event.minimal_attributes,
        'event_type' => event_type.lookup_attributes,
        'badge' => badge.minimal_attributes,
        'team' => team.minimal_attributes,
        'swimmer' => swimmer.minimal_attributes
      ).to_json(options)
    end

    private

    # Returns the "minimum required" hash of associations.
    def minimal_associations
      {
        'meeting_event' => meeting_event.minimal_attributes
        # (^^ This includes: event_type, stroke_type & heat_type)
      }
    end
  end
end
