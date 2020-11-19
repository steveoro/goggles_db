# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
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
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid model instance with',
        %w[city pool_type]
      )
      # Optional associations:
      context 'when the entity contains other optional associations,' do
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
