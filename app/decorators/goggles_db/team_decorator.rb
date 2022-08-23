# frozen_string_literal: true

module GogglesDb
  # = TeamDecorator
  #
  class TeamDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      return editable_name if city_id.nil?

      "#{editable_name}, #{city.decorate&.display_label}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      return editable_name if city_id.nil?

      "#{editable_name}, #{city.name}"
    end
  end
end
