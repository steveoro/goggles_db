# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'
require 'support/shared_calculators_examples'

module GogglesDb
  RSpec.describe Calculators::CSIScore, type: :strategy do
    it_behaves_like 'Calculators::BaseStrategy with valid constructor paramaters'
  end
end
