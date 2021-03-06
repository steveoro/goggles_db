# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe SwimmingPool, type: :model do
    shared_examples_for 'a valid SwimmingPool instance' do
      it 'is valid' do
        expect(subject).to be_a(SwimmingPool).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[city pool_type]
      )

      # Presence of fields & requiredness:
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
      subject { SwimmingPool.all.sample }
      it_behaves_like('a valid SwimmingPool instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:swimming_pool) }
      it_behaves_like('a valid SwimmingPool instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    subject { FactoryBot.create(:swimming_pool) }

    # Sorting scopes:
    describe 'self.by_name' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', SwimmingPool, 'name', 'name')
    end
    describe 'self.by_city' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', SwimmingPool, 'city', 'name')
    end
    describe 'self.by_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', SwimmingPool, 'pool_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_name' do
      %w[ferrari ferretti comunale].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', SwimmingPool, :for_name, %w[name], filter_text)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      subject { FactoryBot.create(:swimming_pool, city: GogglesDb::City.limit(20).sample).minimal_attributes }
      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[city pool_type shower_type hair_dryer_type locker_cabinet_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      # Test a minimalistic instance first:
      subject do
        FactoryBot.create(
          :swimming_pool,
          city: GogglesDb::City.limit(20).sample,
          shower_type: nil,
          hair_dryer_type: nil,
          locker_cabinet_type: nil
        )
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[city pool_type]
      )
      it_behaves_like(
        '#to_json when called with unset optional associations',
        %w[shower_type hair_dryer_type locker_cabinet_type]
      )

      # Optional associations:
      context 'when the entity contains other optional associations' do
        subject { FactoryBot.create(:swimming_pool) }
        let(:json_hash) do
          expect(subject.shower_type).to be_a(ShowerType).and be_valid
          expect(subject.hair_dryer_type).to be_a(HairDryerType).and be_valid
          expect(subject.locker_cabinet_type).to be_a(LockerCabinetType).and be_valid
          JSON.parse(subject.to_json)
        end

        it_behaves_like(
          '#to_json when the entity contains other optional associations with',
          %w[shower_type hair_dryer_type locker_cabinet_type]
        )
      end
    end
  end
end
