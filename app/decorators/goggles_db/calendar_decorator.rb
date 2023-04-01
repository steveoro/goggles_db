# frozen_string_literal: true

module GogglesDb
  # = CalendarDecorator
  #
  class CalendarDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      return decorated_meeting.display_label if meeting

      "#{season_type.short_name}, #{scheduled_date} #{month}: #{meeting_name || '?'}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row.
    # Returns an unstyled string.
    def short_label
      return decorated_meeting.short_label if meeting

      "#{season_type.short_name} (#{year}, #{month}): #{meeting_name || '?'}"
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns the decorated Meeting +Date+ if the Meeting is set.
    # Returns calendar's +scheduled_date+ otherwise.
    def meeting_date
      return decorated_meeting.meeting_date.to_s if meeting

      "#{scheduled_date} #{month} #{year}"
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns the decorated meeting instance, memoized, if available.
    def decorated_meeting
      @decorated_meeting ||= meeting&.decorate
    end
  end
end
