# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_reservation, class: 'GogglesDb::MeetingReservation' do
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

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
