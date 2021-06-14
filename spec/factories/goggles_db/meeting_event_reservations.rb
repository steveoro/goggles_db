FactoryBot.define do
  factory :meeting_event_reservation, class: 'GogglesDb::MeetingEventReservation' do
    before_create_validate_instance

    meeting_event       { create(:meeting_event_individual) }
    meeting_reservation { create(:meeting_reservation, meeting: meeting_event.meeting) }
    meeting             { meeting_event.meeting }
    badge               { meeting_reservation.badge }
    team                { badge.team }
    swimmer             { badge.swimmer }
    minutes             { ((rand * 2) % 2).to_i }
    seconds             { ((rand * 59) % 59).to_i }
    hundredths          { ((rand * 100) % 99).to_i }
    accepted            { true }
    #-- -----------------------------------------------------------------------
    #++
  end
end
