# frozen_string_literal: true

class CreateBest50mResults < ActiveRecord::Migration[6.1]
  def change
    create_view :best_50m_results
  end
end
