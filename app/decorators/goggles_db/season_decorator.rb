# frozen_string_literal: true

module GogglesDb
  # = SeasonDecorator
  #
  class SeasonDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{season_type.short_name} #{header_year}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "#{federation_type.short_name} #{header_year}"
    end
  end
end
