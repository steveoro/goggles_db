# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe GoggleCup do
    shared_examples_for 'a valid GoggleCup instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[team]
      )

      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[team_id season_year description]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[team_id season_year description swimmers_ids ranking_data]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:goggle_cup) }

      it_behaves_like('a valid GoggleCup instance')
    end

    describe 'validations' do
      describe 'season_year' do
        it 'is invalid when not an integer' do
          goggle_cup = FactoryBot.build(:goggle_cup, season_year: 'abc')
          expect(goggle_cup).not_to be_valid
          expect(goggle_cup.errors[:season_year]).to be_present
        end

        it 'is invalid when <= 2000' do
          goggle_cup = FactoryBot.build(:goggle_cup, season_year: 1999)
          expect(goggle_cup).not_to be_valid
          expect(goggle_cup.errors[:season_year]).to be_present
        end
      end

      describe 'description uniqueness scoped to [team_id, season_year]' do
        let(:team) { GogglesDb::Team.first || FactoryBot.create(:team) }

        it 'is invalid with a duplicate description for the same team and season_year' do
          FactoryBot.create(:goggle_cup, team: team, season_year: 2025, description: 'Cup A')
          duplicate = FactoryBot.build(:goggle_cup, team: team, season_year: 2025, description: 'Cup A')
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:description]).to be_present
        end

        it 'is valid with the same description but different team or season_year' do
          FactoryBot.create(:goggle_cup, team: team, season_year: 2025, description: 'Cup B')
          other = FactoryBot.build(:goggle_cup, team: team, season_year: 2026, description: 'Cup B')
          expect(other).to be_valid
        end
      end
    end

    describe 'new columns' do
      it 'responds to swimmers_ids' do
        expect(described_class.column_names).to include('swimmers_ids')
      end

      it 'responds to ranking_data' do
        expect(described_class.column_names).to include('ranking_data')
      end

      it 'defaults swimmers_ids to nil' do
        goggle_cup = FactoryBot.create(:goggle_cup)
        expect(goggle_cup.swimmers_ids).to be_nil
      end

      it 'defaults ranking_data to nil' do
        goggle_cup = FactoryBot.create(:goggle_cup)
        expect(goggle_cup.ranking_data).to be_nil
      end
    end

    describe '#swimmer_ids_array' do
      it 'returns an empty array when swimmers_ids is nil' do
        goggle_cup = FactoryBot.build(:goggle_cup, swimmers_ids: nil)
        expect(goggle_cup.swimmer_ids_array).to eq([])
      end

      it 'parses comma-separated IDs into an array of integers' do
        goggle_cup = FactoryBot.build(:goggle_cup, swimmers_ids: '1,2,3')
        expect(goggle_cup.swimmer_ids_array).to eq([1, 2, 3])
      end

      it 'handles blank and zero values gracefully' do
        goggle_cup = FactoryBot.build(:goggle_cup, swimmers_ids: '1,,0,3')
        expect(goggle_cup.swimmer_ids_array).to eq([1, 3])
      end
    end

    describe '#swimmer_ids_array=' do
      it 'sets swimmers_ids as a comma-separated string from an array' do
        goggle_cup = FactoryBot.build(:goggle_cup)
        goggle_cup.swimmer_ids_array = [1, 2, 3]
        expect(goggle_cup.swimmers_ids).to eq('1,2,3')
      end

      it 'handles string values in the array' do
        goggle_cup = FactoryBot.build(:goggle_cup)
        goggle_cup.swimmer_ids_array = %w[1 2 3]
        expect(goggle_cup.swimmers_ids).to eq('1,2,3')
      end

      it 'handles empty array' do
        goggle_cup = FactoryBot.build(:goggle_cup)
        goggle_cup.swimmer_ids_array = []
        expect(goggle_cup.swimmers_ids).to eq('')
      end
    end
  end
end
