FactoryBot.define do
  factory :season_personal_standard, class: 'GogglesDb::SeasonPersonalStandard' do
    before_create_validate_instance

    season
    swimmer
    pool_type { GogglesDb::PoolType.all_eventable.sample }
    event_type do
      GogglesDb::EventsByPoolType.eventable.individuals
                                 .for_pool_type(pool_type)
                                 .event_length_between(50, 800)
                                 .sample
                                 .event_type
    end

    minutes  { ((rand * 2) % 2).to_i }
    seconds  { ((rand * 59) % 59).to_i }
    hundredths { ((rand * 100) % 99).to_i }
    #-- -----------------------------------------------------------------------
    #++
  end
end
