# frozen_string_literal: true

module GogglesDb
  #
  # = ApplicationRecord abstract model
  #
  # Shared methods container
  #
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Returns the attribute Hash stripped of any attribute used for internal management.
    # (lock_version, timestamps...).
    #
    def minimal_attributes
      attributes.reject { |att_name, _att_value| %w[lock_version created_at updated_at].include?(att_name) }
    end
  end
end
