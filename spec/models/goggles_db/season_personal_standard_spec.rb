# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe SeasonPersonalStandard, type: :model do
    shared_examples_for 'a valid SeasonPersonalStandard instance' do
      it 'is valid' do
        expect(subject).to be_a(SeasonPersonalStandard).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season swimmer pool_type event_type season_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[exists_for? find_first]
      )
    end

    context 'any pre-seeded instance' do
      subject { SeasonPersonalStandard.all.limit(20).sample }
      it_behaves_like('a valid SeasonPersonalStandard instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:season_personal_standard) }
      it_behaves_like('a valid SeasonPersonalStandard instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', SeasonPersonalStandard, 'season', 'header_year')
    end
    describe 'self.by_event_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', SeasonPersonalStandard, 'event_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', SeasonPersonalStandard, 'season')
    end
    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', SeasonPersonalStandard, 'swimmer')
    end
    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', SeasonPersonalStandard, 'pool_type')
    end
    describe 'self.by_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', SeasonPersonalStandard, 'event_type')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:season_personal_standard) }
      it_behaves_like 'TimingManageable'
    end

    describe 'self.exists_for?' do
      context 'when there are matching rows for the specified parameters,' do
        let(:fixture_row) { FactoryBot.create(:season_personal_standard) }
        subject { SeasonPersonalStandard.exists_for?(fixture_row.season, fixture_row.swimmer, fixture_row.pool_type, fixture_row.event_type) }
        it 'is true' do
          expect(fixture_row).to be_a(SeasonPersonalStandard).and be_valid
          expect(subject).to be true
        end
      end

      context 'when no matches are found for the specified parameters,' do
        let(:empty_season) { FactoryBot.create(:season) }
        subject { SeasonPersonalStandard.exists_for?(empty_season, Swimmer.first, PoolType.first, EventType.first) }
        it 'is false' do
          expect(empty_season).to be_a(Season).and be_valid
          expect(subject).to be false
        end
      end
    end

    describe 'self.find_first' do
      context 'when there are matching rows for the specified parameters,' do
        let(:fixture_row) { FactoryBot.create(:season_personal_standard) }
        subject { SeasonPersonalStandard.find_first(fixture_row.season, fixture_row.swimmer, fixture_row.pool_type, fixture_row.event_type) }
        it 'is an instance of SeasonPersonalStandard' do
          expect(subject).to be_a(SeasonPersonalStandard).and be_valid
        end
        it 'matches the filtering parameters' do
          expect(subject).to eq(fixture_row)
        end
      end

      context 'when no matches are found for the specified parameters,' do
        let(:empty_season) { FactoryBot.create(:season) }
        subject { SeasonPersonalStandard.find_first(empty_season, Swimmer.first, PoolType.first, EventType.first) }
        it 'is nil' do
          expect(subject).to be nil
        end
      end
    end
  end
end
