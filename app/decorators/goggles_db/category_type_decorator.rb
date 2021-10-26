# frozen_string_literal: true

module GogglesDb
  # = CategoryTypeDecorator
  #
  class CategoryTypeDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "#{short_name}, #{federation_type.short_name} #{group_name} #{season.header_year}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "(#{season.header_year}) #{short_name}"
    end
  end
end
