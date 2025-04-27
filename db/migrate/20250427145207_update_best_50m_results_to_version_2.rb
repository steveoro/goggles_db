# frozen_string_literal: true

class UpdateBest50mResultsToVersion2 < ActiveRecord::Migration[6.1]
  def change
    update_view :best_50m_results,
                version: 2,
                revert_to_version: 1
  end
end
