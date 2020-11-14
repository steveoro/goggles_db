# frozen_string_literal: true

FactoryBot.define do
  factory :computed_season_ranking, class: 'GogglesDb::ComputedSeasonRanking' do
    team
    season
    rank         { [1, 2, 3].sample }
    total_points { (rand * 5000).to_i + 1 }
  end
end
