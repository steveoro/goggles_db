# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Badge, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:badge) }

      it 'is valid' do
        expect(subject).to be_a(Badge).and be_valid
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
        %i[header_year
           off_gogglecup? fees_due? badge_due? relays_due?
           season_type gender_type
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
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', Badge, 'season', 'begin_date')
    end
    describe 'self.by_swimmer' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', Badge, 'swimmer', 'complete_name')
    end
    describe 'self.by_category_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', Badge, 'category_type', 'code')
    end

    # Filtering scopes:
    describe 'self.for_category_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', Badge, 'category_type')
    end
    describe 'self.for_gender_type' do
      it_behaves_like('filtering scope for_gender_type', Badge)
    end
    describe 'self.for_season_type' do
      it_behaves_like('filtering scope for_season_type', Badge)
    end
    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', Badge, 'season')
    end
    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', Badge, 'team')
    end
    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', Badge, 'swimmer')
    end
    describe 'self.for_years' do
      it_behaves_like('filtering scope for_years', Badge)
    end
    describe 'self.for_year' do
      it_behaves_like('filtering scope for_year', Badge)
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      subject { FactoryBot.create(:badge) }

      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[swimmer gender_type team_affiliation season team category_type entry_time_type]
      )
    end
  end
end
