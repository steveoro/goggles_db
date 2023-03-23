# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

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

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[number]
      )
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

    describe '#minimal_attributes' do
      subject { fixture_badge.minimal_attributes }

      let(:fixture_badge) { FactoryBot.create(:badge) }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      %w[gender_type category_type entry_time_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
      it "contains the 'synthetized' swimmer details" do
        expect(subject['swimmer']).to be_an(Hash).and be_present
        expect(subject['swimmer']).to eq(fixture_badge.swimmer_attributes)
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:badge) }

      let(:json_hash) { JSON.parse(subject.to_json) }

      # Required keys:
      %w[
        display_label short_label
        swimmer gender_type team_affiliation season team
        category_type entry_time_type
      ].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(json_hash[member_name]).to be_present
        end
      end

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(json_hash[method_name]).to eq(subject.decorate.send(method_name))
        end
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[swimmer gender_type team_affiliation season team category_type entry_time_type]
      )
    end
  end
end
