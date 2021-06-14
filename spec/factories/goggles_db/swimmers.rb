FactoryBot.define do
  trait :common_swimmer_fields do
    first_name                { FFaker::Name.first_name }
    last_name                 { FFaker::Name.last_name }
    gender_type               { GogglesDb::GenderType.send(%w[male female].sample) }
    year_of_birth             { 18.years.ago.year - ((rand * 100) % 70).to_i }
    # Adding a random number here prevents the row from unfullilling the unique constraint
    # for very large sets of fixture data or when anonimizing the whole DB:
    complete_name             { "#{last_name} #{first_name} #{(rand * 100_000).to_i}" }
  end

  factory :swimmer, class: 'GogglesDb::Swimmer' do
    before_create_validate_instance

    common_swimmer_fields
    e_mail                  { "#{first_name}.#{last_name}-#{(rand * 1000).to_i}@#{%w[fake.example.com fake.example.org fake.example.net].sample}" }
    nickname                { "#{first_name[0..5]} the #{FFaker::AnimalUS.common_name[0..15]}" }
    associated_user_id      { nil }
    #-- -----------------------------------------------------------------------
    #++
  end
end
