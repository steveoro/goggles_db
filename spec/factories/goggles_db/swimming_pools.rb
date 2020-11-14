# frozen_string_literal: true

FactoryBot.define do
  factory :swimming_pool, class: 'GogglesDb::SwimmingPool' do
    name                    { "#{FFaker::Address.street_name} pool" }
    nick_name               { FFaker::Address.street_name.downcase.gsub(' ', '') }
    address                 { FFaker::Address.street_address }
    lanes_number            { [6, 8, 10].sample }
    has_multiple_pools      { [false, true].sample }
    has_open_area           { [false, true].sample }
    has_bar                 { [false, true].sample }
    has_restaurant_service  { [false, true].sample }
    has_gym_area            { [false, true].sample }
    has_children_area       { [false, true].sample }
    pool_type               { GogglesDb::PoolType.eventable.sample }

    city
  end
end
