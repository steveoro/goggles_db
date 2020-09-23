FactoryBot.define do
  factory :team, class: 'GogglesDb::Team' do
    city
    name          { "#{city.name} Swimming Club ASD" }
    editable_name { name }
    address       { FFaker::Address.street_address }
    phone_mobile  { FFaker::PhoneNumber.phone_number }
    phone_number  { FFaker::PhoneNumber.phone_number }
    e_mail        { FFaker::Internet.email }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
