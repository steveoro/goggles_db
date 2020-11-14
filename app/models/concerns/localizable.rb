# frozen_string_literal: true

require 'active_support'

#
# = Localizable
#
#   Concrete Interface for I18n helper methods.
#   Assumes to be included into an ActiveRecord::Base sibling (it must respond to self.table_name)
#   and it must have a #code field.
#
#   - version:  7.030
#   - author:   Steve A.
#
module Localizable
  extend ActiveSupport::Concern

  # Computes a localized shorter description for the value/code associated with this data
  # Supports override for current locale.
  def label(locale_override = I18n.locale)
    I18n.t("label_#{code}".to_sym, scope: [self.class.scope_sym], locale: locale_override)
  end

  # Computes a localized description for the value/code associated with this data
  # Supports override for current locale.
  def long_label(locale_override = I18n.locale)
    I18n.t("long_label_#{code}".to_sym, scope: [self.class.scope_sym], locale: locale_override)
  end

  # Computes an alternate localized description for the value/code associated with this data.
  # Note that this may not always be defined inside the locale files.
  # Supports override for current locale.
  def alt_label(locale_override = I18n.locale)
    # TODO: Add existance check for I18n.t result; when not found, return default i18n_short result.
    I18n.t("alt_label_#{code}".to_sym, scope: [self.class.scope_sym], locale: locale_override)
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
end
