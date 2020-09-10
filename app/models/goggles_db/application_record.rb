# frozen_string_literal: true

module GogglesDb
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
