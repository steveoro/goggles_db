FactoryBot.define do
  trait :random_badge_code do
    number { FFaker.numerify('#########') }
  end

  factory :badge, class: 'GogglesDb::Badge' do
    random_badge_code
    swimmer
    category_type
    team_affiliation { FactoryBot.create(:team_affiliation, season: category_type.season) }
    season           { category_type.season }
    team             { team_affiliation.team }
    entry_time_type  { GogglesDb::EntryTimeType.send(%w[manual personal gogglecup prec_year last_race].sample) }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
