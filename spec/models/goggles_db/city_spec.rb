# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe City, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:city) }

      it 'is valid' do
        expect(subject).to be_a(City).and be_valid
      end

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name country_code country]
      )
    end
  end
end
