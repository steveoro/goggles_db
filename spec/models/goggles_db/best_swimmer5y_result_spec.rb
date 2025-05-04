# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_best_result_examples'

module GogglesDb
  RSpec.describe BestSwimmer5yResult do
    context 'shared behaviors' do
      # Include shared examples for common AbstractBestResult behavior
      it_behaves_like('an AbstractBestResult descendant', described_class)

      # Include shared examples for scopes
      it_behaves_like('AbstractBestResult filtering scopes', described_class)
      it_behaves_like('AbstractBestResult sorting scopes', described_class)
    end

    # Add specific tests for Best50And100Result if needed in the future
  end
end
