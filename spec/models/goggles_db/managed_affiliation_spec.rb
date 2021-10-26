# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_to_json_examples'

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

    describe '#minimal_attributes' do
      subject { described_class.limit(100).sample.minimal_attributes }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      %w[display_label short_label manager team_affiliation].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      subject { described_class.limit(200).sample }

      # Required keys:
      %w[display_label short_label manager team_affiliation].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(subject.to_json[member_name]).to be_present
        end
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[manager team_affiliation]
      )
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
