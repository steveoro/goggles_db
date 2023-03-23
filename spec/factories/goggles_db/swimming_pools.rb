# frozen_string_literal: true

FactoryBot.define do
  factory :swimming_pool, class: 'GogglesDb::SwimmingPool' do
    before_create_validate_instance

    name           { "#{FFaker::Address.street_name} pool" }
    nick_name      { "#{FFaker::Address.street_name.downcase.delete(' ')}-#{pool_type.length_in_meters}-#{(rand * 10_000).to_i}" }
    address        { FFaker::Address.street_address }
    lanes_number   { [6, 8, 10].sample }
    multiple_pools { [false, true].sample }
    garden         { [false, true].sample }
    bar            { [false, true].sample }
    restaurant     { [false, true].sample }
    gym            { [false, true].sample }
    child_area     { [false, true].sample }
    pool_type      { GogglesDb::PoolType.all_eventable.sample }
    city

    # Optional:
    locker_cabinet_type { GogglesDb::LockerCabinetType.all.sample }
    shower_type         { GogglesDb::ShowerType.all.sample }
    hair_dryer_type     { GogglesDb::HairDryerType.all.sample }
    #-- -----------------------------------------------------------------------
    #++
  end
end
