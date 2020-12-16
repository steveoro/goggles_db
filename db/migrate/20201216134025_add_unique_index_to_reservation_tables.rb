# frozen_string_literal: true

class AddUniqueIndexToReservationTables < ActiveRecord::Migration[6.0]
  def change
    add_index :meeting_event_reservations,
              %i[meeting_id badge_id team_id swimmer_id meeting_event_id],
              name: :idx_unique_event_reservation,
              unique: true

    add_index :meeting_relay_reservations,
              %i[meeting_id badge_id team_id swimmer_id meeting_event_id],
              name: :idx_unique_relay_reservation,
              unique: true
  end
end
