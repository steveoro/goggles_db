# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_relay_reservation, class: 'GogglesDb::MeetingRelayReservation' do
    meeting_event         { create(:meeting_event_relay) }
    meeting_reservation   { create(:meeting_reservation, meeting: meeting_event.meeting) }
    meeting               { meeting_event.meeting }
    badge                 { meeting_reservation.badge }
    team                  { badge.team }
    swimmer               { badge.swimmer }
    user
    accepted              { true }
    notes                 { nil }
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
