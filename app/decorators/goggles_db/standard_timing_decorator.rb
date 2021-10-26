# frozen_string_literal: true

module GogglesDb
  # = StandardTimingDecorator
  #
  class StandardTimingDecorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string which does *NOT* include the actual timing data (that is, a "pure" label).
    # Supports current locale override.
    #
    # == Params
    # - <tt>locale_code</tt>: the locale code override; defaults to <tt>I18n.locale</tt>
    def display_label(locale_code = I18n.locale)
      "#{event_type.label(locale_code)} [#{pool_type.label(locale_code)}] - #{category_type.decorate.display_label}, #{gender_type.label(locale_code)}"
    end

    # Alternative label method for displaying a shorter version of the data available
    # for the current instance row.
    # Returns an unstyled string which does *NOT* include the actual timing data (that is, a "pure" label).
    # Supports current locale override.
    #
    # == Params
    # - <tt>locale_code</tt>: the locale code override; defaults to <tt>I18n.locale</tt>
    def short_label(locale_code = I18n.locale)
      "#{event_type.label(locale_code)} [#{pool_type.label(locale_code)}] - #{category_type.short_name} #{gender_type.label(locale_code)}"
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
