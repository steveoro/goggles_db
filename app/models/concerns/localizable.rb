# frozen_string_literal: true

require 'active_support'

#
# = Localizable
#
#   Concrete Interface for I18n helper methods.
#   Assumes to be included into an ActiveRecord::Base sibling (it must respond to self.table_name)
#   and it must have a #code field.
#
#   - version:  7.02.18
#   - author:   Steve A.
#
module Localizable
  extend ActiveSupport::Concern

  # [Steve A.] Can't enforce checking respond_to? in includees here, because since ver.7 this
  # concern is included in a shared abstract class (can't be instantiated).
  # (@see TimingManageable for code examples)

  # Computes a localized shorter description for the value/code associated with this data.
  # Supports a locale override code.
  def label(locale_override = I18n.locale)
    result = possible_localization('label', locale_override)
    # For certain lookup entities most localized text is not defined yet and the default
    # label is expected to be the code itself:
    return code if result.starts_with?('translation missing:')

    result
  end

  # Computes a localized description for the value/code associated with this data.
  # Supports a locale override code.
  def long_label(locale_override = I18n.locale)
    result = possible_localization('long_label', locale_override)
    return code if result.starts_with?('translation missing:')

    result
  end

  # Computes an alternate localized description for the value/code associated with this data.
  # Note that this may not always be defined inside the locale files (defaults to 'label' in that case).
  # Supports a locale override code.
  def alt_label(locale_override = I18n.locale)
    result = possible_localization('alt_label', locale_override)
    # 'alt_label' is optional most of the times; we fall back to the default 'label' result:
    return label(locale_override) if result.starts_with?('translation missing:')

    result
  end
  #-- -------------------------------------------------------------------------
  #++

  # Meta: adds the following methods to the class of the includee
  module ClassMethods
    # Returns the scope symbol used for grouping the localization strings.
    def scope_sym
      table_name.to_sym
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  private

  # Search for an I18n translation, given the method name and a possible locale override.
  def possible_localization(caller_name, locale_override)
    I18n.t("#{caller_name}_#{code}".to_sym, scope: [self.class.scope_sym], locale: locale_override)
  end
end
