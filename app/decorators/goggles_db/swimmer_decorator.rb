# frozen_string_literal: true

module GogglesDb
  # = SwimmerDecorator
  #
  class SwimmerDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    # Supports current locale override.
    #
    # == Params
    # - <tt>locale_code</tt>: the locale code override; defaults to <tt>I18n.locale</tt>
    def display_label(locale_code = I18n.locale)
      "#{complete_name} (#{gender_type&.label(locale_code)}, #{year_of_birth}#{year_guessed ? '~' : ''})"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    def short_label
      "#{complete_name} (#{year_of_birth}#{year_guessed ? '~' : ''})"
    end
  end
end
