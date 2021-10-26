# frozen_string_literal: true

module GogglesDb
  # = ManagedAffiliationDecorator
  #
  class ManagedAffiliationDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    def display_label
      "🗣  #{manager.decorate.display_label} ➡ #{team_affiliation.decorate.short_label}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "🗣  #{manager.decorate.short_label} ➡ #{team_affiliation.decorate.short_label}"
    end
  end
end
