# frozen_string_literal: true

module GogglesDb
  # = UserDecorator
  #
  class UserDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{name} - #{email} (#{description}, #{year_of_birth})"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "#{name} (#{description})"
    end
  end
end
