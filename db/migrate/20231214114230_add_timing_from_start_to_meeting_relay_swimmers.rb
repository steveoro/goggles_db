# frozen_string_literal: true

class AddTimingFromStartToMeetingRelaySwimmers < ActiveRecord::Migration[6.0]
  def change
    add_column :meeting_relay_swimmers, :length_in_meters, :integer
    add_column :meeting_relay_swimmers, :minutes_from_start, :integer, limit: 3
    add_column :meeting_relay_swimmers, :seconds_from_start, :integer, limit: 2
    add_column :meeting_relay_swimmers, :hundredths_from_start, :integer, limit: 2
  end
end
