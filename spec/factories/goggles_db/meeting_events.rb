# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_event, class: 'GogglesDb::MeetingEvent' do
    sequence(:event_order)

    meeting_session { create(:meeting_session) }
    heat_type       { GogglesDb::HeatType.all.sample }
    event_type do
      GogglesDb::EventsByPoolType.eventable
                                 .for_pool_type(meeting_session.pool_type)
                                 .event_length_between(50, 800)
                                 .sample
                                 .event_type
    end

    factory :meeting_event_individual do
      event_type do
        GogglesDb::EventsByPoolType.eventable.individuals
                                   .for_pool_type(meeting_session.pool_type)
                                   .event_length_between(50, 1500)
                                   .sample
                                   .event_type
      end
    end

    factory :meeting_event_relay do
      event_type do
        GogglesDb::EventsByPoolType.eventable.relays
                                   .for_pool_type(meeting_session.pool_type)
                                   .event_length_between(50, 800)
                                   .sample
                                   .event_type
      end
    end
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
