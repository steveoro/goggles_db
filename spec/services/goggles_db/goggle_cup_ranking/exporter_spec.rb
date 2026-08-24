# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GoggleCupRanking::Exporter do
  let(:team) { FactoryBot.create(:team) }
  let(:swimmer) { FactoryBot.create(:swimmer, complete_name: 'TEST SWIMMER', year_of_birth: 1980) }
  let(:ranking_json) do
    {
      description: 'Test Cup', season_year: 2025, max_points: 1000, team_id: team.id,
      end_date: '2026-07-31', swimmer_ids: [swimmer.id], no_duplicated_events: false,
      data: {
        base_timings: {
          swimmer.id.to_s => [
            {
              'event_type_code' => '50SL', 'pool_type_code' => '25',
              'season_header_year' => 2022, 'total_hundredths' => 3100,
              'meeting_date' => '2022-02-01', 'meeting_name' => 'Base Meeting',
              'meeting_id' => 7, 'meeting_individual_result_id' => 777
            }
          ]
        },
        scores: {
          swimmer.id.to_s => [
            {
              'event_type_code' => '50SL', 'pool_type_code' => '25',
              'total_hundredths' => 3000, 'meeting_date' => '2025-01-15',
              'meeting_name' => 'Test Meeting', 'meeting_id' => 42,
              'meeting_individual_result_id' => 99, 'team_id' => team.id,
              'team_name' => 'TEST TEAM', 'old_total_hundredths' => 3200,
              'old_meeting_date' => '2024-01-10', 'old_meeting_name' => 'Old Meeting',
              'old_meeting_id' => 30, 'old_meeting_individual_result_id' => 88,
              'row_score' => 1066.67
            }
          ]
        }
      }
    }.to_json
  end
  let(:cup) { FactoryBot.create(:goggle_cup, team: team, description: 'Test Cup', season_year: 2025, ranking_data: ranking_json) }
  let(:ranking_data) { GogglesDb::GoggleCupRanking::DataDeserializer.new(cup).call }
  let(:exporter) { described_class.new(cup: cup, ranking_data: ranking_data, no_duplicated_events: false) }

  describe '#export' do
    it 'returns nil when there is no ranking data' do
      empty_exporter = described_class.new(cup: cup, ranking_data: [])
      expect(empty_exporter.export(format_name: :csv, export_type: :ranking)).to be_nil
    end

    it 'returns nil when there are no base timings' do
      no_base = described_class.new(cup: cup, ranking_data: [])
      expect(no_base.export(format_name: :csv, export_type: :base_timings)).to be_nil
    end

    it 'returns a hash with data, filename and mime type for a ranking CSV' do
      result = exporter.export(format_name: :csv, export_type: :ranking)
      expect(result).to include(:data, :filename, :mime_type)
      expect(result[:data]).to include('TEST SWIMMER')
      expect(result[:data]).to include('1066.67')
      expect(result[:filename]).to end_with('.csv')
      expect(result[:mime_type]).to eq('text/csv')
    end

    it 'returns binary data for a ranking XLSX' do
      result = exporter.export(format_name: :xlsx, export_type: :ranking)
      expect(result[:data]).to be_a(String)
      expect(result[:data]).not_to be_empty
      expect(result[:filename]).to end_with('.xlsx')
      expect(result[:mime_type]).to include('spreadsheetml')
    end

    it 'returns binary data for a ranking PDF' do
      result = exporter.export(format_name: :pdf, export_type: :ranking)
      expect(result[:data]).to be_a(String)
      expect(result[:data]).not_to be_empty
      expect(result[:filename]).to end_with('.pdf')
      expect(result[:mime_type]).to eq('application/pdf')
    end

    it 'exports base timings sorted by swimmer name' do
      result = exporter.export(format_name: :csv, export_type: :base_timings)
      expect(result[:data]).to include('TEST SWIMMER')
      expect(result[:data]).to include('50SL')
      expect(result[:filename]).to include('base-timings')
    end

    it 'returns binary data for base timings XLSX' do
      result = exporter.export(format_name: :xlsx, export_type: :base_timings)
      expect(result[:data]).not_to be_empty
      expect(result[:filename]).to include('base-timings').and end_with('.xlsx')
    end

    it 'returns binary data for base timings PDF' do
      result = exporter.export(format_name: :pdf, export_type: :base_timings)
      expect(result[:data]).not_to be_empty
      expect(result[:filename]).to include('base-timings').and end_with('.pdf')
    end
  end

  describe '#filename' do
    it 'includes team, season and description' do
      filename = exporter.filename(format: :csv, export_type: :ranking)
      expect(filename).to include('goggle-cup-2025')
      expect(filename).to include(team.name.parameterize)
      expect(filename).to include('test-cup')
    end

    it 'adds a base-timings suffix' do
      filename = exporter.filename(format: :xlsx, export_type: :base_timings)
      expect(filename).to include('base-timings')
    end
  end

  context 'with a nil cup and explicit team/description/season' do
    let(:live_exporter) do
      described_class.new(
        cup: nil, team: team, ranking_data: ranking_data,
        no_duplicated_events: false,
        description: 'Live Cup', season_year: 2024
      )
    end

    it 'uses the provided metadata for the filename' do
      filename = live_exporter.filename(format: :csv, export_type: :ranking)
      expect(filename).to include('goggle-cup-2024')
      expect(filename).to include('live-cup')
    end

    it 'still produces ranking export data' do
      result = live_exporter.export(format_name: :csv, export_type: :ranking)
      expect(result[:data]).to include('TEST SWIMMER')
    end
  end
end
