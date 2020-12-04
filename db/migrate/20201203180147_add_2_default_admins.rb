# frozen_string_literal: true

class Add2DefaultAdmins < ActiveRecord::Migration[6.0]
  def self.up
    GogglesDb::AdminGrant.create!(user_id: 1)
    GogglesDb::AdminGrant.create!(user_id: 2)
  end

  def self.down
    GogglesDb::AdminGrant.delete!(user_id: 1)
    GogglesDb::AdminGrant.delete!(user_id: 2)
  end
end
