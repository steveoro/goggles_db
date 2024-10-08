# frozen_string_literal: true

require 'scenic/mysql_adapter'

Scenic.configure do |config|
  config.database = Scenic::Adapters::MySQL.new
end
