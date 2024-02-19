# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe APIDailyUse do
    shared_examples_for 'a valid APIDailyUse instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
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

      it_behaves_like('ApplicationRecord shared interface')
    end

    before { expect(minimum_domain.count).to be_positive }

    #-- ------------------------------------------------------------------------
    #++

    let(:minimum_domain) do
      ((Time.zone.today - 7.days)..Time.zone.today).each { |day| FactoryBot.create(:api_daily_use, day:) }
      expect(described_class.count).to be >= 7
      # Add 1 more row just to have a static route to test:
      FactoryBot.create(:api_daily_use, route: 'GET /fake/route')
      described_class.all
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:api_daily_use) }

      it_behaves_like('a valid APIDailyUse instance')
    end

    # Sorting scopes:
    describe 'self.by_date' do
      let(:result) { minimum_domain.by_date }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'day')
    end

    # Filtering scopes:
    describe 'self.for_date' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_date', 'day', Time.zone.today)
    end

    describe 'self.for_route' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_route', 'route', 'GET /fake/route')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.increase_for!' do
      context 'given the chosen (route, day) tuple exists,' do
        let(:existing_row) { minimum_domain.sample }

        it 'increases its value by 1' do
          expect { described_class.increase_for!(existing_row.route, existing_row.day) }.to change { existing_row.reload.count }.by(1)
        end
      end

      context 'if the chosen (route, day) tuple is new,' do
        let(:new_built_row) { FactoryBot.build(:api_daily_use) }

        it 'creates a corresponding row, setting its initial value to 1' do
          expect { described_class.increase_for!(new_built_row.route, new_built_row.day) }.to change(described_class, :count).by(1)
          expect(described_class.where(route: new_built_row.route, day: new_built_row.day).first.count).to eq(1)
        end
      end
    end
  end
end
