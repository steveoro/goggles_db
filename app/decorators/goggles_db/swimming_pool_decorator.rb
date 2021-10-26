# frozen_string_literal: true

module GogglesDb
  # = SwimmingPoolDecorator
  #
  class SwimmingPoolDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    # Supports current locale override.
    #
    # == Params
    # - <tt>locale_code</tt>: the locale code override; defaults to <tt>I18n.locale</tt>
    def display_label(locale_code = I18n.locale)
      "#{name} ('#{nick_name}', #{pool_type.label(locale_code)}), #{city&.decorate&.display_label}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row. Returns an unstyled string.
    # Supports current locale override.
    #
    # == Params
    # - <tt>locale_code</tt>: the locale code override; defaults to <tt>I18n.locale</tt>
    def short_label(locale_code = I18n.locale)
      "#{name} (#{pool_type.label(locale_code)}), #{city&.name}"
    end
  end
end
