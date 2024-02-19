# frozen_string_literal: true

module GogglesDb
  #
  # = TeamAlias model
  #
  # Stores all encountered aliases for a possible name.
  # Legacy name: 'data_import_swimmer_aliases'.
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class TeamAlias < ApplicationRecord
    self.table_name = 'team_aliases'

    belongs_to :team
    validates_associated :team

    default_scope { includes(:team) }

    validates :name, presence: { length: { within: 1..60 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }
  end
end
