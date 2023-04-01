FactoryBot.define do
  factory :meeting_program, class: 'GogglesDb::MeetingProgram' do
    before_create_validate_instance

    sequence(:event_order)

    meeting_event { FactoryBot.create(:meeting_event) }
    gender_type   { GogglesDb::GenderType.send(%w[male female].sample) }
    pool_type     { meeting_event.meeting_session.swimming_pool.pool_type }
    # This will yield a coherent category according to the event type, but regardless of season:
    category_type do
      meeting_event.relay? ? GogglesDb::CategoryType.eventable.relays.sample : GogglesDb::CategoryType.eventable.individuals.sample
    end

    factory :meeting_program_individual do
      meeting_event { FactoryBot.create(:meeting_event_individual) }
    end

    factory :meeting_program_relay do
      meeting_event { FactoryBot.create(:meeting_event_relay) }
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
