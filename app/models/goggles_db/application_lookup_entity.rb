# frozen_string_literal: true

module GogglesDb
  #
  # = ApplicationLookupEntity abstract model
  #
  # Encapsulates common behavior for in-memory lookup entities.
  # Typical usage: short tables that store data that seldom needs any update.
  #
  #   - version:  7.047
  #   - author:   Steve A.
  #
  class ApplicationLookupEntity < ApplicationRecord
    self.abstract_class = true

    include Localizable

    validates :code, presence: { length: { within: 1..3 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }
    #-- -----------------------------------------------------------------------
    #++

    # Returns a minimal subset of this instance's attribute hash merged with the localized display
    # labels ('label', 'long_label', 'alt_label').
    #
    # === Params:
    # - locale: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    def lookup_attributes(locale = I18n.locale)
      minimal_attributes.merge(
        'label' => label(locale),
        'long_label' => long_label(locale),
        'alt_label' => alt_label(locale)
      )
    end

    # Override: includes additional #lookup_attributes.
    #
    # === Options:
    # - locale: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    def to_json(options = nil)
      locale_override = options&.fetch(:locale, nil) || I18n.locale
      lookup_attributes(locale_override)
        .to_json(options)
    end
  end
end
