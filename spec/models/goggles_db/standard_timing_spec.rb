# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe StandardTiming, type: :model do
    shared_examples_for 'a valid StandardTiming instance' do
      it 'is valid' do
        expect(subject).to be_a(StandardTiming).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season pool_type event_type gender_type category_type season_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[exists_for? find_first]
      )
    end

    context 'any pre-seeded instance' do
      subject { StandardTiming.all.limit(20).sample }
      it_behaves_like('a valid StandardTiming instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:standard_timing) }
      it_behaves_like('a valid StandardTiming instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', StandardTiming, 'season', 'header_year')
    end
    describe 'self.by_event_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', StandardTiming, 'event_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', StandardTiming, 'season')
    end
    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', StandardTiming, 'pool_type')
    end
    describe 'self.by_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', StandardTiming, 'event_type')
    end
    describe 'self.for_gender_type' do
      it_behaves_like('filtering scope for_gender_type', StandardTiming)
    end
    describe 'self.for_category_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', StandardTiming, 'category_type')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:standard_timing) }
      it_behaves_like 'TimingManageable'
    end

    describe 'self.exists_for?' do
      context 'when there are matching rows for the specified parameters,' do
        let(:fixture_row) { FactoryBot.create(:standard_timing) }
        subject do
          StandardTiming.exists_for?(
            fixture_row.season,
            fixture_row.pool_type,
            fixture_row.event_type,
            fixture_row.gender_type,
            fixture_row.category_type
          )
        end
        it 'is true' do
          expect(fixture_row).to be_a(StandardTiming).and be_valid
          expect(subject).to be true
        end
      end

      context 'when no matches are found for the specified parameters,' do
        let(:empty_season) { FactoryBot.create(:season) }
        subject { StandardTiming.exists_for?(empty_season, PoolType.first, EventType.first, GenderType.first, CategoryType.first) }
        it 'is false' do
          expect(empty_season).to be_a(Season).and be_valid
          expect(subject).to be false
        end
      end
    end

    describe 'self.find_first' do
      context 'when there are matching rows for the specified parameters,' do
        let(:fixture_row) { FactoryBot.create(:standard_timing) }
        subject do
          StandardTiming.find_first(
            fixture_row.season,
            fixture_row.pool_type,
            fixture_row.event_type,
            fixture_row.gender_type,
            fixture_row.category_type
          )
        end
        it 'is an instance of StandardTiming' do
          expect(subject).to be_a(StandardTiming).and be_valid
        end
        it 'matches the filtering parameters' do
          expect(subject).to eq(fixture_row)
        end
      end

      context 'when no matches are found for the specified parameters,' do
        let(:empty_season) { FactoryBot.create(:season) }
        subject { StandardTiming.find_first(empty_season, PoolType.first, EventType.first, GenderType.first, CategoryType.first) }
        it 'is nil' do
          expect(subject).to be nil
        end
      end
    end
  end
end
