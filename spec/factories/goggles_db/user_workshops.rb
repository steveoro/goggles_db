FactoryBot.define do
  factory :user_workshop, class: 'GogglesDb::UserWorkshop' do
    before_create_validate_instance

    sequence(:code) { |n| "workshop-#{n}" }
    description     { "#{FFaker::Name.suffix} #{FFaker::Address.city} Workshop" }
    edition         { (1..40).to_a.sample }
    season          { create(:season) }
    header_date     { season.begin_date + (rand * 100).to_i.days }
    header_year     { season.header_year }
    edition_type    { GogglesDb::EditionType.send(%w[ordinal roman none yearly seasonal].sample) }
    timing_type     { GogglesDb::TimingType.send(%w[manual semiauto automatic].sample) }

    user            # Workshops must have a "creator"
    team            # (default team - not needed)
    swimming_pool   { nil } # (No default pool)

    notes           { FFaker::Lorem.sentence }
    autofilled      { [false, true].sample }
    off_season      { [false, true].sample }
    confirmed       { [false, true].sample }
    cancelled       { false }
    pb_acquired     { false }
    read_only       { false }

    factory :workshop_with_results do
      after(:create) do |created_instance, _evaluator|
        create_list(:user_result, 4, user_workshop: created_instance)
      end
    end

    factory :workshop_with_results_and_laps do
      after(:create) do |created_instance, _evaluator|
        create_list(:user_result_with_laps, 4, user_workshop: created_instance)
      end
    end
  end
end
