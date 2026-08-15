# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GoggleCupRanking::DataDeserializer do
  describe '#call' do
    let(:ranking_data) do
      {
        description: 'Test Cup',
        season_year: 2025,
        max_points: 1000,
        team_id: team.id,
        swimmer_ids: [1],
        no_duplicated_events: true,
        data: {
          base_timings: {
            '1' => [
              {
                'event_type_code' => '50SL', 'pool_type_code' => '50',
                'season_header_year' => 2022, 'meeting_date' => '2022-01-15',
                'meeting_name' => 'Old Meeting', 'meeting_id' => 1,
                'meeting_individual_result_id' => 1, 'total_hundredths' => 1200
              }
            ]
          },
          scores: {
            '1' => [
              {
                'event_type_code' => '50SL', 'pool_type_code' => '50',
                'season_header_year' => 2025, 'meeting_date' => '2025-01-15',
                'meeting_name' => 'Current Meeting', 'meeting_id' => 2,
                'meeting_individual_result_id' => 2, 'total_hundredths' => 1100,
                'old_meeting_date' => '2022-01-15', 'old_meeting_name' => 'Old Meeting',
                'old_meeting_id' => 1, 'old_meeting_individual_result_id' => 1,
                'old_total_hundredths' => 1200, 'row_score' => 1090.91
              }
            ]
          }
        }
      }.to_json
    end

    let(:team) { FactoryBot.create(:team) }
    let(:cup) { FactoryBot.create(:goggle_cup, team: team, ranking_data: ranking_data) }

    it 'returns an array of ranking entries' do
      result = described_class.new(cup).call
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
    end

    it 'includes swimmer info, top rows and base rows' do
      result = described_class.new(cup).call.first
      expect(result[:top_rows].size).to eq(1)
      expect(result[:base_rows].size).to eq(1)
      expect(result[:top_rows].first[:row_score]).to be_within(0.01).of(1090.91)
      expect(result[:overall_score]).to be_within(0.01).of(1090.91)
    end

    it 'wraps stored rows in ScoreRow objects' do
      result = described_class.new(cup).call.first
      expect(result[:top_rows].first[:row]).to respond_to(:event_type_code)
      expect(result[:base_rows].first).to respond_to(:event_type_code)
    end

    context 'with blank ranking_data' do
      let(:cup) { FactoryBot.create(:goggle_cup, team: team, ranking_data: nil) }

      it 'returns an empty array' do
        expect(described_class.new(cup).call).to be_empty
      end
    end
  end
end
