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

    # Optional:
    locker_cabinet_type { GogglesDb::LockerCabinetType.all.sample }
    shower_type         { GogglesDb::ShowerType.all.sample }
    hair_dryer_type     { GogglesDb::HairDryerType.all.sample }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
