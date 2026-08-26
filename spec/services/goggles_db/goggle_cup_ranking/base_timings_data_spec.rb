# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GoggleCupRanking::BaseTimingsData do
  let(:base_timing_row_class) do
    Struct.new(
      :event_type_code, :pool_type_code, :season_header_year, :total_hundredths,
      :meeting_date, :meeting_name, :meeting_id, :meeting_individual_result_id
    )
  end

  let(:ranking_data) do
    [
      {
        swimmer_id: 1,
        swimmer_name: 'Zeta Swimmer',
        swimmer_year_of_birth: 1980,
        overall_score: 1000.0,
        base_rows: [
          base_timing_row_class.new('50SL', '25', 2022, 3100, '2022-02-01', 'Base Meeting', 7, 777)
        ],
        top_rows: []
      },
      {
        swimmer_id: 2,
        swimmer_name: 'Alpha Swimmer',
        swimmer_year_of_birth: 1990,
        overall_score: 1050.0,
        base_rows: [
          base_timing_row_class.new('100SL', '50', 2021, 6500, '2021-03-15', 'Older Meeting', 8, 888)
        ],
        top_rows: []
      },
      {
        swimmer_id: 3,
        swimmer_name: 'No Base Swimmer',
        swimmer_year_of_birth: 2000,
        overall_score: 900.0,
        base_rows: [],
        top_rows: []
      }
    ]
  end

  describe '#call' do
    it 'excludes swimmers with no base rows' do
      result = described_class.new(ranking_data).call
      expect(result.pluck(:swimmer_id)).not_to include(3)
    end

    it 'sorts by swimmer name' do
      result = described_class.new(ranking_data).call
      expect(result.pluck(:swimmer_name)).to eq(['Alpha Swimmer', 'Zeta Swimmer'])
    end

    it 'preserves the base rows for each swimmer' do
      result = described_class.new(ranking_data).call
      expect(result.first[:base_rows].size).to eq(1)
      expect(result.first[:base_rows].first.meeting_id).to eq(8)
    end

    context 'with nil ranking_data' do
      it 'returns an empty array' do
        expect(described_class.new(nil).call).to be_empty
      end
    end
  end
end
