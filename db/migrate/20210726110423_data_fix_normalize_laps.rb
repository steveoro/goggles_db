# frozen_string_literal: true

class DataFixNormalizeLaps < ActiveRecord::Migration[6.0]
  def self.up
    puts "\r\n--> Lap & UserLap normalization..."
    Rake::Task['app:normalize:laps'].invoke
  end

  def self.down
    # (no-op)
  end
end
