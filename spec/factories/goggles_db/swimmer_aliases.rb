FactoryBot.define do
  factory :swimmer_alias, class: 'GogglesDb::SwimmerAlias' do
    before_create_validate_instance

    swimmer
    complete_name { "#{swimmer.last_name} #{FFaker::Name.first_name} #{swimmer.first_name} #{(rand * 100_000).to_i}" }
  end
end
