# frozen_string_literal: true

FactoryBot.define do
  factory :goggle_cup, class: 'GogglesDb::GoggleCup' do
    before_create_validate_instance

    team
    description { "Goggle Cup #{FFaker.numerify('###')}" }
    season_year { 2025 }
    swimmers_ids { nil }
    ranking_data { nil }
  end
end
