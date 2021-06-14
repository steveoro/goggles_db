# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_reservation, class: 'GogglesDb::MeetingReservation' do
    before_create_validate_instance

    badge                 { create(:badge) }
    meeting               { create(:meeting, season: badge.season) }
    team                  { badge.team }
    swimmer               { badge.swimmer }
    user
    notes                 { FFaker::Lorem.paragraph }
    not_coming            { false }
    confirmed             { false }
    #-- -----------------------------------------------------------------------
    #++
  end
end
