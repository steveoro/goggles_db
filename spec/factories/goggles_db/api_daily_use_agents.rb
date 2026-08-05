# frozen_string_literal: true

FactoryBot.define do
  factory :api_daily_use_agent, class: 'GogglesDb::APIDailyUseAgent' do
    sequence(:user_agent) { |n| "Mozilla/5.0 (Test #{n})" }
    day   { Time.zone.today }
    count { 0 }
  end
end
