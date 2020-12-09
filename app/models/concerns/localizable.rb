# frozen_string_literal: true

require 'active_support'

#
# = Localizable
#
#   Concrete Interface for I18n helper methods.
#   Assumes to be included into an ActiveRecord::Base sibling (it must respond to self.table_name)
#   and it must have a #code field.
#
#   - version:  7.040
#   - author:   Steve A.
#
module Localizable
  extend ActiveSupport::Concern

  # [Steve A.] Can't enforce checking respond_to? in includees here, because since ver.7 this
  # concern is included in a shared abstract class (can't be instantiated).
  # (For more information, compare implementation difference w/ TimingManageable.)

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

  # Override: includes localized description labels as additional attibutes.
  #
  # === Options:
  #
  # - locale: an valid locale code symbol (:it', :en, :fr, :de, ...) to be used as
  #           I18n.locale enforce/override
  #
  def to_json(options = nil)
    locale_override = options&.fetch(:locale, nil) || I18n.locale
    attributes.merge(
      'label' => label(locale_override),
      'long_label' => long_label(locale_override),
      'alt_label' => alt_label(locale_override)
    ).to_json(options)
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
