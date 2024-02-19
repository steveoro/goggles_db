# frozen_string_literal: true

module GogglesDb
  #
  # = ApplicationRecord abstract model
  #
  #   - version:  7-0.5.13
  #   - author:   Steve A.
  #
  # Shared methods container
  #
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Returns the hash of model attributes (column keys and values) minus fields needed
    # only for internal usage.
    #
    # As of this version, only the following fields will be filtered out:
    # - lock_version
    #
    # == Returns:
    # The filtered attribute hash
    #
    def model_attributes
      attributes.except('lock_version')
    end

    # Returns the attribute Hash stripped of any attribute used for internal management.
    # (lock_version, timestamps...).
    # Includes the standard labels ('label', 'long_label', 'alt_label') when available.
    #
    # === Params:
    # - locale: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    def minimal_attributes(locale = I18n.locale)
      result_hash = model_attributes
      if respond_to?(:label) && respond_to?(:long_label) && respond_to?(:alt_label)
        result_hash.merge!(
          'label' => label(locale),
          'long_label' => long_label(locale),
          'alt_label' => alt_label(locale)
        )
      end
      result_hash
    end

    # Returns the list of all association names (as Strings) available for the current model instance,
    # given a specific association type filter.
    #
    # == Params:
    # - <tt>filter</tt>: any among <tt>:has_many</tt>, <tt>:has_one</tt>, <tt>:belongs_to</tt>;
    #                    leave default value for no filters.
    #
    def all_associations(filter = nil)
      self.class.reflect_on_all_associations(filter).map { |a| a.name.to_s }
    end

    # Returns the list of single association names (as Strings), be it belongs_to (N:1 or has_one (1:1)
    # available for the current model instance.
    # Does not include the association if it doesn't respond to <tt>#minimal_attributes</tt>.
    #
    # Override this in siblings to limit the list of associations included by <tt>#to_hash</tt>
    # (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      all_associations(:belongs_to).select { |key| send(key).respond_to?(:minimal_attributes) } +
        all_associations(:has_one).select { |key| send(key).respond_to?(:minimal_attributes) }
    end

    # Returns the list of multiple (has_many, 1:N) association names (as symbols) available
    # for the current model instance.
    # Does not include the association if it currently doesn't have any row in it.
    #
    # Override this in siblings to limit the list of associations included by <tt>#to_hash</tt>
    # (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      # Include only 1:N associations with actual rows in it:
      all_associations(:has_many).reject { |key| !send(key).respond_to?(:count) || send(key).count.zero? }
    end

    # Returns a structured Hash representing a serializable version of the current model
    # instance, having as keys:
    #
    # - all the <tt>#minimal_attributes</tt>
    # - all the associations
    # - for each association, an Array of Hash of all the <tt>#minimal_attributes</tt> for each model
    #   present in the hierarchy tree.
    #
    # === Options:
    # - max_siblings: max number of siblings rows returned when including each row (first(max_siblings)).
    # - locale: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    def to_hash(options = nil)
      locale_override = options&.fetch(:locale, nil) || I18n.locale
      max_siblings = options&.fetch(:max_siblings, nil) || 20

      minimal_attributes(locale_override)
        .merge(map_single_associations_attributes(locale_override))
        .merge(map_multiple_associations_attributes(max_siblings, locale_override))
    end

    # Override: converts <tt>#to_hash</tt> into JSON in order to have a richer and more detailed
    # API output.
    #
    # === Options:
    # - max_siblings: max number of siblings rows returned when including each row (first(max_siblings)).
    # - locale: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    # Other supported options: any option hash accepted by JSON#generate (spaces, indentation, formatting, ...).
    #
    def to_json(options = nil)
      to_hash(options).to_json(options)
    end

    private

    # Returns the structured Hash mapping all attributes from each sub-entity enlisted in <tt>#single_associations</tt>.
    #
    # === Params:
    # - locale_override: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    def map_single_associations_attributes(locale_override)
      result_hash = {}
      serialized_self = readonly? ? self : self.class.includes(single_associations).find(id)

      single_associations.each do |key|
        next unless serialized_self.send(key).respond_to?(:minimal_attributes)

        result_hash[key.to_s] = map_attributes_from_model(serialized_self.send(key), locale_override)
      end
      result_hash
    end

    # Returns the structured Hash mapping all attributes from *each row*, from each sub-entity
    # enlisted in <tt>#multiple_associations</tt>, with a max_siblings-limit row for each sub-entity.
    #
    # === Params:
    # - max_siblings: max number of siblings rows returned when including each row (first(max_siblings)).
    # - locale_override: a valid locale code or symbol ('it', 'en', ...) to be used as I18n.locale enforce/override
    #
    def map_multiple_associations_attributes(max_siblings, locale_override)
      result_hash = {}
      # Sending each key here will yield an array of instances (i.e. MIR.send(:laps)),
      # so we need to recursively map the (min) attributes for each one of those:
      multiple_associations.each do |key|
        domain = send(key)
        next unless domain.respond_to?(:map) && domain.respond_to?(:first) && domain.respond_to?(:count)
        next unless domain.count.positive?

        result_hash[key.to_s] = domain.first(max_siblings)
                                      .map { |row| map_attributes_from_model(row, locale_override) }
      end
      result_hash
    end

    # Maps all the attributes from the specified +row+ model instance into an Hash,
    # either using a bespoke attribute collector version ('<MODEL_NAME>_attributes', when available)
    # or the standardized <tt>minimal_attributes</tt>.
    #
    # The bespoke attribute collector must be defined inside the model yielding the association.
    # E.g.: "TeamAffiliation -> Team", in T.A. we can define a "team_attributes" that
    # will be yield to return a bespoke attribute list for the associated Team row.
    #
    # If the bespoke attribute collector isn't found, the standard "minimal_attributes"
    # will be called instead.
    #
    # == Params:
    # - row: an associated model instance
    # - locale: string or symbol for the locale override
    #
    def map_attributes_from_model(row, locale = I18n.locale)
      custom_attr_helper = "#{row.class.name.split('::').last.tableize.singularize}_attributes"
      return send(custom_attr_helper) if respond_to?(custom_attr_helper)
      return unless row.respond_to?(:minimal_attributes)

      row.minimal_attributes(locale)
    end
  end
end
