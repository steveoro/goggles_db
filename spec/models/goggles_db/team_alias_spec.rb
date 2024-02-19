# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe TeamAlias do
    shared_examples_for 'a valid TeamAlias instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[team]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name team_id]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[name team_id]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid TeamAlias instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team_alias) }

      it_behaves_like('a valid TeamAlias instance')
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
