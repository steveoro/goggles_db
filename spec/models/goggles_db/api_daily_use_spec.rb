# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe ApiDailyUse, type: :model do
    shared_examples_for 'a valid ApiDailyUse instance' do
      it 'is valid' do
        expect(subject).to be_an(ApiDailyUse).and be_valid
      end

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[route day count]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[increase_for!]
      )
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:api_daily_use) }
      it_behaves_like('a valid ApiDailyUse instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:minimum_domain) do
      ((Date.today - 7.days)..Date.today).each { |day| FactoryBot.create(:api_daily_use, day: day) }
      expect(ApiDailyUse.count).to be >= 7
      # Add 1 more row just to have a static route to test:
      FactoryBot.create(:api_daily_use, route: 'GET /fake/route')
      ApiDailyUse.all
    end

    before(:each) { expect(minimum_domain.count).to be_positive }

    # Sorting scopes:
    describe 'self.by_date' do
      let(:result) { minimum_domain.by_date }
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', ApiDailyUse, 'day')
    end

    # Filtering scopes:
    describe 'self.for_date' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', ApiDailyUse, 'for_date', 'day', Date.today)
    end
    describe 'self.for_route' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', ApiDailyUse, 'for_route', 'route', 'GET /fake/route')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.increase_for!' do
      context 'given the chosen (route, day) tuple exists,' do
        let(:existing_row) { minimum_domain.sample }

        it 'increases its value by 1' do
          expect { ApiDailyUse.increase_for!(existing_row.route, existing_row.day) }.to change { existing_row.reload.count }.by(1)
        end
      end

      context 'if the chosen (route, day) tuple is new,' do
        let(:new_built_row) { FactoryBot.build(:api_daily_use) }

        it 'creates a corresponding row, setting its initial value to 1' do
          expect { ApiDailyUse.increase_for!(new_built_row.route, new_built_row.day) }.to change { ApiDailyUse.count }.by(1)
          expect(ApiDailyUse.where(route: new_built_row.route, day: new_built_row.day).first.count).to eq(1)
        end
      end
    end
  end
end
