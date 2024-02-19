# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe SwimmingPool do
    subject { described_class.first(200).sample }

    shared_examples_for 'a valid SwimmingPool instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[city pool_type]
      )

      # Presence of fields & required-ness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name nick_name lanes_number]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[by_name by_city by_pool_type
           for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[shower_type hair_dryer_type locker_cabinet_type
           address phone_number fax_number e_mail contact_name
           multiple_pools? garden? bar? restaurant? gym? child_area?
           read_only? city_name to_json]
      )
    end

    context 'any pre-seeded instance' do
      it_behaves_like('a valid SwimmingPool instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:swimming_pool) }

      it_behaves_like('a valid SwimmingPool instance')
    end

    # Sorting scopes:
    describe 'self.by_name' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'name', 'name')
    end

    describe 'self.by_city' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'city', 'name')
    end

    describe 'self.by_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'pool_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_name' do
      %w[melato verola ferrari ferretti comunale].each do |filter_text|
        it_behaves_like(
          'filtering scope FULLTEXT for_...', described_class, :for_name,
          %w[name nick_name address], filter_text
        )
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { FactoryBot.create(:swimming_pool, city: GogglesDb::City.limit(20).sample) }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end

      it 'includes the city name & decorated label' do
        expect(result['city_name']).to eq(fixture_row.city.name)
        expect(result['city_label']).to eq(fixture_row.city.decorate.short_label)
      end

      it 'includes the pool_code' do
        expect(result['pool_code']).to eq(fixture_row.pool_type.code)
      end
    end

    describe '#to_hash' do
      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[city pool_type]
      )

      # Optional associations:
      context 'when the entity contains other optional associations' do
        subject { FactoryBot.create(:swimming_pool) } # full associations

        it_behaves_like(
          '#to_hash when the entity has any 1:1 optional association with',
          %w[shower_type hair_dryer_type locker_cabinet_type]
        )
      end
    end
  end
end
