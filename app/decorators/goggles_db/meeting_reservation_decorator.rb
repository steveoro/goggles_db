# frozen_string_literal: true

module GogglesDb
  # = MeetingReservationDecorator
  #
  class MeetingReservationDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{meeting.decorate.display_label} ➡ #{badge.decorate.short_label}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "#{meeting.decorate.short_label} ➡ #{swimmer.decorate.short_label}"
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end