# frozen_string_literal: true

class AmendManagedAffiliations < ActiveRecord::Migration[6.0]
  def self.up
    GogglesDb::ManagedAffiliation.where('user_id > 4').delete_all
  end

  def self.down
    # Can't go back to old data after this:
    raise ActiveRecord::IrreversibleMigration
  end
end
