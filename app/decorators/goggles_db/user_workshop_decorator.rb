# frozen_string_literal: true

module GogglesDb
  # = UserWorkshopDecorator
  #
  class UserWorkshopDecorator < Draper::Decorator
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

    # Returns the list of scheduled event +Date+s for this user workshop.
    # Returns +nil+ when no results have been defined yet.
    def scheduled_dates
      user_results.map(&:event_date).uniq
    end

    # Returns the first scheduled +Date+ for this workshop or +nil+ otherwise.
    def scheduled_date
      scheduled_dates&.first
    end

    # Returns the workshop +Date+ as set on its header if the actual event +Date+
    # is not set yet. The header +Date+ is never +nil+ for UserWorkshops.
    def meeting_date
      scheduled_date || header_date
    end
    #-- -----------------------------------------------------------------------
    #++

    # Returns the list of SwimmingPool defined for this workshop, ordered by session.
    # Returns +nil+ whenever the sessions or the pools are missing.
    def meeting_pools
      user_results.map(&:swimming_pool).uniq
    end

    # Returns the first representative or default SwimmingPool for this workshop.
    # Returns +nil+ whenever the sessions or the pools are missing.
    def meeting_pool
      swimming_pool || meeting_pools&.first
    end

    # Returns the list of all defined +EventType+s for this instance,
    # ordered by user result date.
    #
    # == Example usage:
    #
    # To prepare a label list of all the event types:
    #
    #   > event_type_list.map(&:label)
    #
    def event_type_list
      user_results.map(&:event_type).flatten.uniq
    end
  end
end
