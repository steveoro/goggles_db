# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe SeasonPersonalStandard do
    shared_examples_for 'a valid SeasonPersonalStandard instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season swimmer pool_type event_type season_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[exists_for? find_first]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

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
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'header_year')
    end

    describe 'self.by_event_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'event_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'season')
    end

    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'swimmer')
    end

    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'pool_type')
    end

    describe 'self.by_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'event_type')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:season_personal_standard) }

      it_behaves_like 'TimingManageable'
    end

    describe 'self.exists_for?' do
      context 'when there are matching rows for the specified parameters,' do
        subject { described_class.exists_for?(fixture_row.season, fixture_row.swimmer, fixture_row.pool_type, fixture_row.event_type) }

        let(:fixture_row) { FactoryBot.create(:season_personal_standard) }

        it 'is true' do
          expect(fixture_row).to be_a(described_class).and be_valid
          expect(subject).to be true
        end
      end

      context 'when no matches are found for the specified parameters,' do
        subject { described_class.exists_for?(empty_season, Swimmer.first, PoolType.first, EventType.first) }

        let(:empty_season) { FactoryBot.create(:season) }

        it 'is false' do
          expect(empty_season).to be_a(Season).and be_valid
          expect(subject).to be false
        end
      end
    end

    describe 'self.find_first' do
      context 'when there are matching rows for the specified parameters,' do
        subject { described_class.find_first(fixture_row.season, fixture_row.swimmer, fixture_row.pool_type, fixture_row.event_type) }

        let(:fixture_row) { FactoryBot.create(:season_personal_standard) }

        it 'is an instance of SeasonPersonalStandard' do
          expect(subject).to be_a(described_class).and be_valid
        end

        it 'matches the filtering parameters' do
          expect(subject).to eq(fixture_row)
        end
      end

      context 'when no matches are found for the specified parameters,' do
        subject { described_class.find_first(empty_season, Swimmer.first, PoolType.first, EventType.first) }

        let(:empty_season) { FactoryBot.create(:season) }

        it 'is nil' do
          expect(subject).to be_nil
        end
      end
    end
  end
end
