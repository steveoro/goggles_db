# frozen_string_literal: true

class FixCitiesAreaName < ActiveRecord::Migration[6.0]
  def change
    # Fix missing accent:
    GogglesDb::City.where(area: 'FORLI-CESENA').update_all(area: 'Forlì-Cesena')
  end
end
