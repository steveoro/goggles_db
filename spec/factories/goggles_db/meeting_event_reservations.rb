FactoryBot.define do
  factory :meeting_event_reservation, class: 'GogglesDb::MeetingEventReservation' do
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

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
