# frozen_string_literal: true

module GogglesDb
  # = CityDecorator
  #
  class CityDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{name}, #{area} (#{country_code})"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "#{name}, #{area}"
    end
  end
end
