# frozen_string_literal: true

FactoryBot.define do
  factory :team_lap_template, class: 'GogglesDb::TeamLapTemplate' do
    before_create_validate_instance

    team
    pool_type { GogglesDb::PoolType.all_eventable.sample }
    event_type do
      GogglesDb::EventsByPoolType.eventable.individuals
                                 .for_pool_type(pool_type)
                                 .event_length_between(50, 800)
                                 .sample
                                 .event_type
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
