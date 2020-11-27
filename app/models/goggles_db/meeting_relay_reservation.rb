# frozen_string_literal: true

module GogglesDb
  #
  # = MeetingRelayReservation model
  #
  #   - version:  7.035
  #   - author:   Steve A.
  #
  # Same properties and methods as MeetingEventReservation, with just a different table name
  # (minus the timing fields).
  #
  class MeetingRelayReservation < MeetingEventReservation
    self.table_name = 'meeting_relay_reservations'
  end
end
