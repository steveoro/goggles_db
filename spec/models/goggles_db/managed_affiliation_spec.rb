# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe ManagedAffiliation, type: :model do
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
  end
end
