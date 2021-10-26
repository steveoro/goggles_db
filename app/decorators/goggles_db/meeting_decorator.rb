# frozen_string_literal: true

module GogglesDb
  # = MeetingDecorator
  #
  class MeetingDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{season_type.short_name}: #{name_with_edition}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      name_with_edition(condensed_name)
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns the list of scheduled +Date+s for this meeting.
    # Returns +nil+ when no meeting sessions have been defined yet.
    def scheduled_dates
      meeting_sessions.by_order.map(&:scheduled_date).uniq
    end

    # Returns the first scheduled +Date+ for this meeting or +nil+ otherwise.
    def scheduled_date
      scheduled_dates&.first
    end

    # Returns the Meeting +Date+ as set on its header if the actual scheduled +Date+
    # is not set yet. Be advised that the header +Date+ could be +nil+ too for certain Meetings.
    def meeting_date
      scheduled_date || header_date
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns the list of SwimmingPool defined for this meeting, ordered by session.
    # Returns +nil+ whenever the sessions or the pools are missing.
    def meeting_pools
      meeting_sessions.by_order.map(&:swimming_pool).uniq
    end

    # Returns the first representative SwimmingPool for this meeting.
    # Returns +nil+ whenever the sessions or the pools are missing.
    def meeting_pool
      meeting_pools&.first
    end

    # Returns the list of all defined +MeetingEvent+s for this instance,
    # ordered by session & event order.
    # (Assumes both sessions & events as properly set.)
    def event_list
      meeting_sessions.by_order.map(&:meeting_events).flatten
    end

    # Returns the list of all defined +EventType+s for this instance,
    # ordered by session & event order.
    # (Assumes both sessions & events as properly set.)
    #
    # == Example usage:
    #
    # To prepare a label list of all the event types:
    #
    #   > event_type_list.map(&:label)
    #
    def event_type_list
      event_list.map(&:event_type)
    end
  end
end
