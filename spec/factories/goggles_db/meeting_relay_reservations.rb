# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_relay_reservation, class: 'GogglesDb::MeetingRelayReservation' do
    before_create_validate_instance

    meeting_event         { FactoryBot.create(:meeting_event_relay) }
    meeting_reservation   { FactoryBot.create(:meeting_reservation, meeting: meeting_event.meeting) }
    meeting               { meeting_event.meeting }
    badge                 { meeting_reservation.badge }
    team                  { badge.team }
    swimmer               { badge.swimmer }
    accepted              { true }
    notes                 { nil }
    #-- -----------------------------------------------------------------------
    #++
  end
end
