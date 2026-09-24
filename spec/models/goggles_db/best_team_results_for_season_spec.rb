# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_best_result_examples'

module GogglesDb
  RSpec.describe BestTeamResultsForSeason do
    context 'shared behaviors' do
      # Include shared examples for common AbstractBestResult behavior
      it_behaves_like('an AbstractBestResult descendant', described_class)

      # Include shared examples for scopes
      it_behaves_like('AbstractBestResult filtering scopes', described_class)
      it_behaves_like('AbstractBestResult sorting scopes', described_class)
    end

    it { is_expected.to belong_to(:category_type) }

    describe '.for_category_type' do
      subject(:filtered) { described_class.for_category_type(chosen_category) }

      let(:chosen_category) { GogglesDb::CategoryType.find(described_class.distinct.pluck(:category_type_id).sample) }

      it 'returns only results for the specified category type' do
        expect(filtered.pluck(:category_type_id)).to all(eq(chosen_category.id))
      end
    end

    describe 'tuple uniqueness' do
      subject(:team_season_rows) { described_class.for_team_and_season_ids(chosen.team_id, chosen.season_id) }

      let(:chosen) { described_class.order(Arel.sql('RAND()')).first }

      it 'returns at most one row per event x category x gender x pool tuple' do
        tuples = team_season_rows.pluck(:event_type_id, :category_type_id, :gender_type_id, :pool_type_id)
        expect(tuples.uniq.length).to eq(tuples.length)
      end

      it 'reports only positive timings on non-disqualified results' do
        expect(team_season_rows.pluck(:total_hundredths)).to all(be_positive)
      end

      it 'keeps only results bound to the team through a season badge' do
        badge_team_ids = GogglesDb::Badge.where(
          id: GogglesDb::MeetingIndividualResult.where(id: team_season_rows.select(:meeting_individual_result_id)).select(:badge_id)
        ).distinct.pluck(:team_id)
        expect(badge_team_ids).to eq([chosen.team_id])
      end
    end
  end
end
