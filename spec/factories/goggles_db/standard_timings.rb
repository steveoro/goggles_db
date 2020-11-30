FactoryBot.define do
  factory :standard_timing, class: 'GogglesDb::StandardTiming' do
    season
    pool_type { GogglesDb::PoolType.all_eventable.sample }
    event_type do
      GogglesDb::EventsByPoolType.eventable.individuals
                                 .for_pool_type(pool_type)
                                 .event_length_between(50, 800)
                                 .sample
                                 .event_type
    end
    gender_type   { GogglesDb::GenderType.send(%w[male female].sample) }
    category_type { GogglesDb::CategoryType.eventable.individuals.sample }

    minutes  { ((rand * 2) % 2).to_i }
    seconds  { ((rand * 59) % 59).to_i }
    hundreds { ((rand * 100) % 99).to_i }
    #-- -----------------------------------------------------------------------
    #++

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
