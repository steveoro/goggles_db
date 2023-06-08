# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe ComputedSeasonRanking do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:computed_season_ranking) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[team season]
      )
      it 'has a valid team' do
        expect(subject.team).to be_a(Team).and be_valid
      end

      it 'has a valid season' do
        expect(subject.season).to be_a(Season).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[rank total_points team_name season_description
           to_json]
      )

      # Presence of fields & required-ness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[rank total_points]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_rank' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'rank', 'rank')
    end

    # Filtering scopes:
    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'season')
    end

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_hash' do
      subject { FactoryBot.create(:computed_season_ranking) }

      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[team season]
      )
    end
  end
end
