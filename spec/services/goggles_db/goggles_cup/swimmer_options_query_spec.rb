# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GogglesCup::SwimmerOptionsQuery do
  let(:team) { FactoryBot.create(:team) }
  let(:base_year) { 2024 }
  let!(:current_season) do
    FactoryBot.create(:season, season_type_id: GogglesDb::SeasonType::MAS_FIN_ID,
                               begin_date: Date.new(base_year, 9, 1),
                               end_date: Date.new(base_year + 1, 6, 30))
  end
  let!(:previous_season) do
    FactoryBot.create(:season, season_type_id: GogglesDb::SeasonType::MAS_FIN_ID,
                               begin_date: Date.new(base_year - 1, 9, 1),
                               end_date: Date.new(base_year, 6, 30))
  end
  let!(:current_affiliation) { FactoryBot.create(:team_affiliation, team: team, season: current_season) }
  let!(:previous_affiliation) { FactoryBot.create(:team_affiliation, team: team, season: previous_season) }

  def badge_for(season, affiliation, swimmer = FactoryBot.create(:swimmer))
    FactoryBot.create(:badge, team_affiliation: affiliation, season: season, team: team,
                              category_type: FactoryBot.create(:category_type, season: season),
                              swimmer: swimmer)
  end

  describe '#call' do
    subject(:options) { described_class.new(team_id: team.id, base_year: base_year).call }

    it 'includes swimmers having a badge in the current MASFIN season' do
      badge = badge_for(current_season, current_affiliation)
      expect(options.pluck(:swimmer_id)).to include(badge.swimmer_id)
    end

    it 'includes swimmers having a badge in the previous MASFIN season' do
      badge = badge_for(previous_season, previous_affiliation)
      expect(options.pluck(:swimmer_id)).to include(badge.swimmer_id)
    end

    it 'lists each swimmer only once when holding badges in both seasons' do
      swimmer = FactoryBot.create(:swimmer)
      badge_for(current_season, current_affiliation, swimmer)
      badge_for(previous_season, previous_affiliation, swimmer)
      ids = options.pluck(:swimmer_id)
      expect(ids.count(swimmer.id)).to eq(1)
    end

    it 'excludes badges for non-MASFIN seasons in the same period' do
      other_season = FactoryBot.create(:season, season_type_id: GogglesDb::SeasonType::MAS_CSI_ID,
                                                begin_date: Date.new(base_year, 9, 1),
                                                end_date: Date.new(base_year + 1, 6, 30))
      affiliation = FactoryBot.create(:team_affiliation, team: team, season: other_season)
      badge = badge_for(other_season, affiliation)
      expect(options.pluck(:swimmer_id)).not_to include(badge.swimmer_id)
    end

    it 'excludes badges of other teams' do
      other_badge = FactoryBot.create(:badge, season: current_season)
      expect(options.pluck(:swimmer_id)).not_to include(other_badge.swimmer_id)
    end

    it 'returns rows with swimmer_id, swimmer_name and swimmer_year_of_birth' do
      badge = badge_for(current_season, current_affiliation)
      row = options.find { |r| r[:swimmer_id] == badge.swimmer_id }
      expect(row[:swimmer_name]).to eq(badge.swimmer.complete_name)
      expect(row[:swimmer_year_of_birth]).to eq(badge.swimmer.year_of_birth)
    end
  end

  describe '#smart_selected_ids_for' do
    subject(:query) { described_class.new(team_id: team.id, base_year: base_year) }

    it 'returns the ids of listed swimmers holding a badge for the secondary team' do
      badge = badge_for(current_season, current_affiliation)
      secondary_badge = FactoryBot.create(:badge, swimmer: badge.swimmer)
      expect(query.smart_selected_ids_for(secondary_badge.team_id)).to include(badge.swimmer_id)
    end

    it 'returns an empty list for a blank secondary team' do
      expect(query.smart_selected_ids_for(nil)).to eq([])
    end
  end
end
