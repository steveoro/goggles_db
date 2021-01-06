# frozen_string_literal: true

class AddUniqueIdxOnMeetingReservations < ActiveRecord::Migration[6.0]
  def change
    add_index :meeting_reservations,
              %i[meeting_id badge_id],
              name: :idx_unique_reservation,
              unique: true
  end
end
