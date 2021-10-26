# frozen_string_literal: true

module GogglesDb
  # = BadgeDecorator
  #
  class BadgeDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{season.decorate.display_label}: #{swimmer.decorate.display_label} ➡ #{team.decorate.display_label}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "#{season.decorate.short_label}: #{swimmer.decorate.short_label} ➡ #{team.decorate.short_label}"
    end
  end
end
