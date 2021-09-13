# frozen_string_literal: true

FactoryBot.define do
  factory :api_daily_use, class: 'GogglesDb::APIDailyUse' do
    sequence(:route) { |n| "#{%w[GET POST PUT DELETE].sample} api/v3/#{FFaker::Lorem.word}/#{FFaker::Lorem.word}/#{n}" }
    day   { Time.zone.today }
    count { 0 }
  end
end
