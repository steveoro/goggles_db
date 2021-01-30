# frozen_string_literal: true

class RenameUnder25ToUnder25 < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :meetings, :allows_under_25, :allows_under25
  end

  def self.down
    rename_column :meetings, :allows_under25, :allows_under_25
  end
end
