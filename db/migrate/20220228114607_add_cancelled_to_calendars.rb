# frozen_string_literal: true

class AddCancelledToCalendars < ActiveRecord::Migration[6.0]
  def change
    add_column :calendars, :cancelled, :boolean, default: false
    add_index :calendars, :cancelled
  end
end
