# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GogglesCup::RankingCalculator do
  let(:base_row) do
    {
      swimmer_id: 1,
      swimmer_name: 'TEST SWIMMER',
      swimmer_year_of_birth: 1980,
      event_type_code: '50SL',
      total_hundredths: 3000
    }
  end

  def row(attributes = {})
    instance_double(GogglesDb::BestSwimmerCurrentVsPreviousResult, **base_row, **attributes)
  end

  it 'sets row_score to 1000 when old_total_hundredths is nil' do
    result = described_class.new(team_id: 1, swimmer_ids: [1], rows: [row(old_total_hundredths: nil)]).call

    expect(result.first[:top_rows].first[:row_score]).to eq(1000.0)
  end

  it 'sets row_score to 1000 when old_total_hundredths is zero' do
    result = described_class.new(team_id: 1, swimmer_ids: [1], rows: [row(old_total_hundredths: 0)]).call

    expect(result.first[:top_rows].first[:row_score]).to eq(1000.0)
  end

  it 'adds the improved timing delta when old_total_hundredths is positive' do
    result = described_class.new(team_id: 1, swimmer_ids: [1], rows: [row(old_total_hundredths: 3200)]).call

    expect(result.first[:top_rows].first[:row_score]).to eq(1066.67)
  end

  it 'sums fewer than five rows when fewer are available' do
    rows = [row(old_total_hundredths: 3200), row(old_total_hundredths: nil)]

    result = described_class.new(team_id: 1, swimmer_ids: [1], rows: rows).call

    expect(result.first[:overall_score]).to eq(2066.67)
  end

  it 'sums only the top five row scores' do
    rows = [3600, 3500, 3400, 3300, 3200, 3100].map { |old_time| row(old_total_hundredths: old_time) }

    result = described_class.new(team_id: 1, swimmer_ids: [1], rows: rows).call

    expect(result.first[:overall_score]).to eq(5666.67)
  end

  it 'keeps only the highest scoring row for each event when no duplicated events is enabled' do
    rows = [
      row(event_type_code: '50SL', old_total_hundredths: 3100),
      row(event_type_code: '50SL', old_total_hundredths: 3500),
      row(event_type_code: '100SL', old_total_hundredths: 3200)
    ]

    result = described_class.new(team_id: 1, swimmer_ids: [1], rows: rows, no_duplicated_events: true).call

    expect(result.first[:top_rows].pluck(:row_score)).to eq([1166.67, 1066.67])
  end
end
