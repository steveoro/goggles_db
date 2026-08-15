# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GoggleCupRanking::DataSerializer do
  describe '#call' do
    subject(:result) do
      described_class.new(cup: cup, ranking_data: ranking_data, no_duplicated_events: true).call
    end

    let(:team) { FactoryBot.create(:team) }
    let(:cup) { FactoryBot.create(:goggle_cup, team: team) }

    let(:score_row_hash) do
      {
        'event_type_code' => '50SL', 'pool_type_code' => '50',
        'season_header_year' => 2025, 'meeting_date' => '2025-01-15',
        'meeting_name' => 'Current Meeting', 'meeting_id' => 2,
        'meeting_individual_result_id' => 2, 'total_hundredths' => 1100,
        'old_meeting_date' => '2022-01-15', 'old_meeting_name' => 'Old Meeting',
        'old_meeting_id' => 1, 'old_meeting_individual_result_id' => 1,
        'old_total_hundredths' => 1200
      }
    end
    let(:row_double) do
      instance_double(GogglesDb::BestSwimmerCurrentVsPreviousResult, attributes: score_row_hash)
    end
    let(:ranking_data) do
      [
        {
          swimmer_id: 1,
          swimmer_name: 'Test Swimmer',
          swimmer_year_of_birth: 2000,
          overall_score: 1090.91,
          top_rows: [{ row: row_double, row_score: 1090.91 }]
        }
      ]
    end

    it 'returns a hash with cup metadata' do
      expect(result).to include(:description, :season_year, :max_points, :team_id)
      expect(result[:no_duplicated_events]).to be true
      expect(result[:swimmer_ids]).to eq([])
    end

    it 'stores scores under data.scores keyed by swimmer id' do
      expect(result.dig(:data, :scores)).to have_key('1')
      expect(result.dig(:data, :scores, '1').size).to eq(1)
      expect(result.dig(:data, :scores, '1').first).to have_key('row_score')
    end

    it 'stores base timings under data.base_timings' do
      expect(result.dig(:data, :base_timings)).to be_a(Hash)
    end
  end
end
