# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_calculators_examples'

module GogglesDb
  RSpec.describe Calculators::UISPScore, type: :strategy do
    it_behaves_like 'Calculators::BaseStrategy with valid constructor paramaters'
  end
end
