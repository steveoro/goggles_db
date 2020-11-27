# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_relay_reservation, class: 'GogglesDb::MeetingRelayReservation' do
    meeting_event         { create(:meeting_event_relay) }
    meeting               { create(:meeting, season: meeting_event.season) }
    badge                 { create(:badge, season: meeting_event.season) }
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
