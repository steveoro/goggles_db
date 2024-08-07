# frozen_string_literal: true

module GogglesDb
  #
  # = SwimmerAlias model
  #
  # Stores all encountered aliases for a possible name ('complete_name' only).
  # Legacy name: 'data_import_swimmer_aliases'.
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class SwimmerAlias < ApplicationRecord
    self.table_name = 'swimmer_aliases'

    belongs_to :swimmer
    validates_associated :swimmer

    default_scope { includes(:swimmer) }

    validates :complete_name, presence: { length: { within: 1..100 }, allow_nil: false },
                              uniqueness: { case_sensitive: true, message: :already_exists }
  end
end
