FactoryBot.define do
  factory :user_result, class: 'GogglesDb::UserResult' do
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

    pool_type     { GogglesDb::PoolType.all_eventable.sample }
    category_type { GogglesDb::CategoryType.eventable.individuals.sample }

    event_type do
      GogglesDb::EventsByPoolType.eventable.individuals
                                 .for_pool_type(pool_type)
                                 .event_length_between(50, 1500)
                                 .sample
                                 .event_type
    end

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

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
