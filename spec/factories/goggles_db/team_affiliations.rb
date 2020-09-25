FactoryBot.define do
  factory :team_affiliation, class: 'GogglesDb::TeamAffiliation' do
    team
    season
    name { team.name }
    random_badge_code

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end

    # This will also create the proper team_affiliations:
    factory :affiliation_with_badges do
      after(:create) do |created_instance, _evaluator|
        FactoryBot.create_list(:badge, 2, team_affiliation: created_instance)
        raise "#{created_instance.class} is missing the minimum number of children entites!" unless created_instance.badges.count >= 2
      end
    end
  end
end
