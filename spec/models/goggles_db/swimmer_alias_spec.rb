# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe SwimmerAlias do
    shared_examples_for 'a valid SwimmerAlias instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[complete_name swimmer_id]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[complete_name swimmer_id]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid SwimmerAlias instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:swimmer_alias) }

      it_behaves_like('a valid SwimmerAlias instance')
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
