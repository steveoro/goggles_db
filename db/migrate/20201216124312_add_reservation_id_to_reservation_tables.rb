# frozen_string_literal: true

class AddReservationIdToReservationTables < ActiveRecord::Migration[6.0]
  def change
    add_reference :meeting_event_reservations, :meeting_reservation
    add_reference :meeting_relay_reservations, :meeting_reservation
  end
end
