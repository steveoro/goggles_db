FactoryBot.define do
  factory :city, class: 'GogglesDb::City' do
    before_create_validate_instance

    name          { FFaker::Address.city }
    country       { FFaker::Address.country }
    country_code  { FFaker::Address.country_code }
  end
end
