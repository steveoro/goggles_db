# frozen_string_literal: true

class RenameTimingForMeetingEventReservations < ActiveRecord::Migration[6.0]
  def change
    rename_column :meeting_event_reservations, :suggested_minutes, :minutes
    rename_column :meeting_event_reservations, :suggested_seconds, :seconds
    rename_column :meeting_event_reservations, :suggested_hundreds, :hundreds
  end
end
