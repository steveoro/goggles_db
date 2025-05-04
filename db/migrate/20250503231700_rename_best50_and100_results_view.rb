# frozen_string_literal: true

class RenameBest50And100ResultsView < ActiveRecord::Migration[6.1]
  ORIGINAL_VIEW_NAME = :best50_and100_results
  CONVENTIONAL_VIEW_NAME = :best_50_and_100_results
  VIEW_VERSION = 1

  # Construct file paths relative to Rails.root
  ORIGINAL_SQL_FILE = Rails.root.join('db', 'views', "#{ORIGINAL_VIEW_NAME}_v#{VIEW_VERSION.to_s.rjust(2, '0')}.sql")
  CONVENTIONAL_SQL_FILE = Rails.root.join('db', 'views', "#{CONVENTIONAL_VIEW_NAME}_v#{VIEW_VERSION.to_s.rjust(2, '0')}.sql")

  def up
    say_with_time "Renaming view from #{ORIGINAL_VIEW_NAME} to #{CONVENTIONAL_VIEW_NAME}" do
      # 1. Drop the old view
      drop_view ORIGINAL_VIEW_NAME, revert_to_version: VIEW_VERSION

      # 2. Rename the SQL definition file to match the new view name
      if File.exist?(ORIGINAL_SQL_FILE)
        say "Renaming SQL definition file: #{ORIGINAL_SQL_FILE} -> #{CONVENTIONAL_SQL_FILE}"
        File.rename(ORIGINAL_SQL_FILE, CONVENTIONAL_SQL_FILE)
      else
        say "Warning: Original SQL file not found at #{ORIGINAL_SQL_FILE}. Cannot rename.", true
      end

      # 3. Create the new view (Scenic will now find the renamed SQL file)
      create_view CONVENTIONAL_VIEW_NAME, version: VIEW_VERSION
    end
  end

  def down
    say_with_time "Reverting view rename from #{CONVENTIONAL_VIEW_NAME} to #{ORIGINAL_VIEW_NAME}" do
      # 1. Drop the new view
      drop_view CONVENTIONAL_VIEW_NAME, revert_to_version: VIEW_VERSION

      # 2. Rename the SQL definition file back to the original name
      if File.exist?(CONVENTIONAL_SQL_FILE)
        say "Renaming SQL definition file back: #{CONVENTIONAL_SQL_FILE} -> #{ORIGINAL_SQL_FILE}"
        File.rename(CONVENTIONAL_SQL_FILE, ORIGINAL_SQL_FILE)
      else
        say "Warning: Conventional SQL file not found at #{CONVENTIONAL_SQL_FILE}. Cannot rename back.", true
      end

      # 3. Recreate the original view (Scenic will now find the original SQL file)
      create_view ORIGINAL_VIEW_NAME, version: VIEW_VERSION
    end
  end
end
