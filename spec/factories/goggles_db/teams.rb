FactoryBot.define do
  factory :team, class: 'GogglesDb::Team' do
    city
    name          { "#{city.name} Swimming Club ASD" }
    editable_name { name }
    address       { FFaker::Address.street_address }
    zip           { format('%<number>06d', number: (rand * 100_000).to_i) }
    phone_mobile  { FFaker::PhoneNumber.phone_number }
    phone_number  { FFaker::PhoneNumber.phone_number }
    e_mail        { FFaker::Internet.safe_email }
    contact_name  { FFaker::Name.name }
    notes         { FFaker::BaconIpsum.phrase }
    home_page_url { FFaker::Internet.http_url }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end

    # This will also create the proper team_affiliations:
    factory :team_with_badges do
      after(:create) do |created_instance, _evaluator|
        # Create 2 badges x 2 affiliations:
        FactoryBot.create_list(:affiliation_with_badges, 2, team: created_instance)
        unless created_instance.badges.count >= 4 &&
               created_instance.team_affiliations.count >= 2
          raise "#{created_instance.class} is missing the minimum number of children entites!"
        end
      end
    end
  end
end
