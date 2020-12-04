# frozen_string_literal: true

class DropTableAdmins < ActiveRecord::Migration[6.0]
  def change
    drop_table :admins, if_exists: true
  end
end
