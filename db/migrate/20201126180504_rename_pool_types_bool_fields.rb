# frozen_string_literal: true

class RenamePoolTypesBoolFields < ActiveRecord::Migration[6.0]
  def change
    rename_column :pool_types, :is_suitable_for_meetings, :eventable
  end
end
