FactoryBot.define do
  factory :user, class: 'GogglesDb::User' do
    before_create_validate_instance

    first_name            { FFaker::Name.first_name }
    last_name             { FFaker::Name.last_name }
    name do
      "#{first_name.to_s.downcase.gsub(' ', '.')}.#{last_name.to_s.downcase.gsub(' ', '.')}-#{(rand * 10_000).to_i}"
    end
    email                 { "#{name}@#{%w[fake.example.com fake.example.org fake.example.net].sample}" }
    password              { 'Password123!' }
    password_confirmation { 'Password123!' }
    confirmed_at          { Time.zone.now }
    created_at            { Time.zone.now }
    updated_at            { Time.zone.now }
    current_sign_in_ip    { FFaker::Internet.ip_v4_address }
    last_sign_in_ip       { FFaker::Internet.ip_v4_address }
    description           { "#{first_name} #{last_name}" }
    year_of_birth         { 18.years.ago.year - ((rand * 100) % 60).to_i }
    swimmer_level_type    { GogglesDb::SwimmerLevelType.all.sample }
  end
end
