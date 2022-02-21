# frozen_string_literal: true

module GogglesDb
  # = CalendarDecorator
  #
  class CalendarDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      return meeting.decorate.display_label if meeting

      "#{season_type.short_name}, #{scheduled_date}: #{meeting_name || '?'}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row.
    # Returns an unstyled string.
    def short_label
      return meeting.decorate.short_label if meeting

      "#{season_type.short_name} (#{year}): #{meeting_name || '?'}"
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns the decorated Meeting +Date+ if the Meeting is set.
    # Returns calendar's +scheduled_date+ otherwise.
    def meeting_date
      return meeting.decorate.meeting_date.to_s if meeting

      scheduled_date.to_s
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
