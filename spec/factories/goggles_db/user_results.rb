FactoryBot.define do
  factory :user_result, class: 'GogglesDb::UserResult' do
    before_create_validate_instance

    user_workshop
    swimmer
    user do
      create(
        :user,
        first_name: swimmer.first_name,
        last_name: swimmer.last_name,
        description: swimmer.complete_name,
        year_of_birth: swimmer.year_of_birth
      )
    end

    swimming_pool
    pool_type     { swimming_pool.pool_type }
    category_type { GogglesDb::CategoryType.eventable.individuals.sample }

    event_type do
      GogglesDb::EventsByPoolType.eventable.individuals
                                 .for_pool_type(pool_type)
                                 .event_length_between(50, 1500)
                                 .sample
                                 .event_type
    end

    event_date      { Time.zone.today }
    description     { "#{swimmer.complete_name}, #{event_type.code}" }
    reaction_time   { rand.round(2) }
    minutes         { 0 }
    seconds         { ((rand * 60) % 60).to_i }
    hundredths      { ((rand * 100) % 100).to_i }

    rank            { (0..40).to_a.sample }
    standard_points { (rand * 1000).to_i }
    meeting_points  { standard_points }

    disqualified    { [true, false].sample }
    disqualification_code_type { disqualified ? GogglesDb::DisqualificationCodeType.all.sample : nil }

    factory :user_result_with_laps do
      after(:create) do |created_instance, _evaluator|
        create_list(:user_lap, [2, 4, 8].sample, user_result: created_instance)
      end
    end
  end
end
