# frozen_string_literal: true

class RefactorTeamManagerToManagedAffiliation < ActiveRecord::Migration[6.0]
  def change
    rename_table :team_managers, :managed_affiliations
  end
end
