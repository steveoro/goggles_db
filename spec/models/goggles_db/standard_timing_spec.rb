# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe StandardTiming do
    shared_examples_for 'a valid StandardTiming instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season pool_type event_type gender_type category_type season_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[exists_for? find_first]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

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
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'header_year')
    end

    describe 'self.by_event_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'event_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'season')
    end

    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'pool_type')
    end

    describe 'self.by_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'event_type')
    end

    describe 'self.for_gender_type' do
      it_behaves_like(
        'filtering scope for_<ANY_CHOSEN_FILTER>',
        described_class,
        'for_gender_type',
        'gender_type',
        GogglesDb::GenderType.send(%w[male female].sample)
      )
    end

    describe 'self.for_category_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'category_type')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:standard_timing) }

      it_behaves_like 'TimingManageable'
    end

    describe 'self.exists_for?' do
      context 'when there are matching rows for the specified parameters,' do
        subject do
          described_class.exists_for?(
            fixture_row.season,
            fixture_row.pool_type,
            fixture_row.event_type,
            fixture_row.gender_type,
            fixture_row.category_type
          )
        end

        let(:fixture_row) { FactoryBot.create(:standard_timing) }

        it 'is true' do
          expect(fixture_row).to be_a(described_class).and be_valid
          expect(subject).to be true
        end
      end

      context 'when no matches are found for the specified parameters,' do
        subject { described_class.exists_for?(empty_season, PoolType.first, EventType.first, GenderType.first, CategoryType.first) }

        let(:empty_season) { FactoryBot.create(:season) }

        it 'is false' do
          expect(empty_season).to be_a(Season).and be_valid
          expect(subject).to be false
        end
      end
    end

    describe 'self.find_first' do
      context 'when there are matching rows for the specified parameters,' do
        subject do
          described_class.find_first(
            fixture_row.season,
            fixture_row.pool_type,
            fixture_row.event_type,
            fixture_row.gender_type,
            fixture_row.category_type
          )
        end

        let(:fixture_row) { FactoryBot.create(:standard_timing) }

        it 'is an instance of StandardTiming' do
          expect(subject).to be_a(described_class).and be_valid
        end

        it 'matches the filtering parameters' do
          expect(subject).to eq(fixture_row)
        end
      end

      context 'when no matches are found for the specified parameters,' do
        subject { described_class.find_first(empty_season, PoolType.first, EventType.first, GenderType.first, CategoryType.first) }

        let(:empty_season) { FactoryBot.create(:season) }

        it 'is nil' do
          expect(subject).to be_nil
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.last(200).sample }

      it 'includes the timing string' do
        expect(result['timing']).to eq(fixture_row.to_timing.to_s)
      end

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end
    end

    describe '#to_hash' do
      subject { described_class.first(200).sample }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[season pool_type event_type gender_type category_type]
      )
    end
  end
end
