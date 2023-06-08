# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe Badge do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:badge) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer team_affiliation season team category_type entry_time_type
           season_type gender_type]
      )
      it 'has a valid Swimmer' do
        expect(subject.swimmer).to be_a(Swimmer).and be_valid
      end

      it 'has a valid TeamAffiliation' do
        expect(subject.team_affiliation).to be_a(TeamAffiliation).and be_valid
      end

      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end

      it 'has a valid Team' do
        expect(subject.team).to be_a(Team).and be_valid
      end

      it 'has a valid CategoryType' do
        expect(subject.category_type).to be_a(CategoryType).and be_valid
      end

      it 'has a valid EntryTimeType' do
        expect(subject.entry_time_type).to be_a(EntryTimeType).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[season_type gender_type managed_affiliations
           header_year
           off_gogglecup? fees_due? badge_due? relays_due?
           minimal_attributes swimmer_attributes
           to_json]
      )

      # Presence of fields & required-ness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[number]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'begin_date')
    end

    describe 'self.by_swimmer' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'swimmer', 'complete_name')
    end

    describe 'self.by_category_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'category_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_category_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'category_type')
    end

    describe 'self.for_gender_type' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_gender_type', 'gender_type',
                      GogglesDb::GenderType.send(%w[male female].sample))
    end

    describe 'self.for_season_type' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season_type', 'season_type', GogglesDb::SeasonType.all_masters.sample)
    end

    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'season')
    end

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end

    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'swimmer')
    end

    describe 'self.for_years' do
      it_behaves_like('filtering scope for_years', described_class)
    end

    describe 'self.for_year' do
      it_behaves_like('filtering scope for_year', described_class)
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { FactoryBot.create(:badge) }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end
    end

    describe '#to_hash' do
      subject { FactoryBot.create(:badge) }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[team_affiliation season team category_type entry_time_type season_type gender_type]
      )

      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[swimmer]
      )
    end
  end
end
