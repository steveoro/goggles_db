FactoryBot.define do
  factory :user, class: 'GogglesDb::User' do
    first_name            { FFaker::Name.first_name }
    last_name             { FFaker::Name.last_name }
    name                  { "#{first_name}.#{last_name}-#{(rand * 10_000).to_i}" }
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

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
