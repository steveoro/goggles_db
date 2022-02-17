# frozen_string_literal: true

module GogglesDb
  #
  # = AdminGrant model
  #
  # (previously known as "Admins")
  #
  #   - version:  7-0.3.44
  #   - author:   Steve A.
  #
  # To check if a user has generic admin grants, simply use:
  #
  #    GogglesDb::AdminGrant.exists?(user_id: <USER_ID>, entity: nil)
  #
  # To check if a user has specific admin grants, use:
  #
  #    GogglesDb::AdminGrant.exists?(user_id: <USER_ID>, entity: <ENTITY_NAME>)
  #
  class AdminGrant < ApplicationRecord
    self.table_name = 'admin_grants'

    belongs_to :user
    validates_associated :user

    default_scope { includes(:user) }

    delegate :name, to: :user, prefix: false
  end
end
