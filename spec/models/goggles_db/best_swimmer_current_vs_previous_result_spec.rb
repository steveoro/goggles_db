# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_best_result_examples'

module GogglesDb
  RSpec.describe BestSwimmerCurrentVsPreviousResult do
    context 'shared behaviors' do
      it_behaves_like('an AbstractBestResult descendant', described_class)
      it_behaves_like('AbstractBestResult filtering scopes', described_class)
      it_behaves_like('AbstractBestResult sorting scopes', described_class)
    end

    describe 'old timing columns' do
      it 'exposes old timing fields in the view schema' do
        expect(described_class.column_names).to include('old_minutes', 'old_seconds', 'old_hundredths')
      end
    end
  end
end
