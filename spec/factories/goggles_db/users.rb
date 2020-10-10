FactoryBot.define do
  factory :user, class: 'GogglesDb::User' do
    name                      { "#{FFaker::Internet.user_name}-#{(rand * 1000).to_i}" }
    email                     { FFaker::Internet.email }
    password                  { 'password' }
    password_confirmation     { 'password' }
    confirmed_at              { Time.zone.now }
    created_at                { Time.zone.now }
    updated_at                { Time.zone.now }
    first_name                { FFaker::Name.first_name }
    last_name                 { FFaker::Name.last_name }
    description               { "#{first_name} #{last_name}" }
    year_of_birth             { 18.years.ago.year - ((rand * 100) % 60).to_i }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
