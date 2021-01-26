# frozen_string_literal: true

FactoryBot.define do
  factory :api_daily_use, class: 'GogglesDb::ApiDailyUse' do
    sequence(:route) { |n| "#{%w[GET POST PUT DELETE].sample} api/v3/#{FFaker::Lorem.word}/#{FFaker::Lorem.word}/#{n}" }
    day   { Date.today }
    count { 0 }
  end
end
