# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe ManagedAffiliation do
    shared_examples_for 'a valid ManagedAffiliation instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[team_affiliation team season manager]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[manager_name]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid ManagedAffiliation instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:managed_affiliation) }

      it_behaves_like('a valid ManagedAffiliation instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.limit(200).sample }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end
    end

    describe '#to_hash' do
      subject { described_class.limit(200).sample }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[manager team_affiliation team season]
      )
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
