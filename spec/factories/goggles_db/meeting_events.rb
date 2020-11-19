# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_event, class: 'GogglesDb::MeetingEvent' do
    meeting_session
    sequence(:event_order) { |n| n }
    heat_type { GogglesDb::HeatType.all.sample }
    event_type do
      GogglesDb::EventsByPoolType.for_pool_type(meeting_session.pool_type)
                                 .event_length_between(50, 1500)
                                 .sample
                                 .event_type
    end

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
    #-- -----------------------------------------------------------------------
    #++

    factory :meeting_event_individual do
      event_type do
        GogglesDb::EventsByPoolType.for_pool_type(meeting_session.pool_type)
                                   .individuals
                                   .event_length_between(50, 1500)
                                   .sample
                                   .event_type
      end
    end

    factory :meeting_event_relay do
      event_type do
        GogglesDb::EventsByPoolType.for_pool_type(meeting_session.pool_type)
                                   .relays
                                   .event_length_between(50, 1500)
                                   .sample
                                   .event_type
      end
    end
  end
end
