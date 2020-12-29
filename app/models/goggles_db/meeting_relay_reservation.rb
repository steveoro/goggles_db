# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingRelayReservation model
  #
  #   - version:  7.054
  #   - author:   Steve A.
  #
  # Same properties and methods as MeetingEventReservation, with just a different table name
  # (minus the timing fields).
  #
  # Relay reservations are individual Meeting Relay registrations, added personally by each athlete
  # to signal availability for relay call by the Team Manager.
  #
  class MeetingRelayReservation < MeetingEventReservation
    self.table_name = 'meeting_relay_reservations'
  end
end
