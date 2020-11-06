# frozen_string_literal: true

class RenamePassageTemplatesAndTimeStandard < ActiveRecord::Migration[6.0]
  def change
    rename_table :team_passage_templates, :team_lap_templates
    rename_table :time_standards, :standard_timings
  end
end
