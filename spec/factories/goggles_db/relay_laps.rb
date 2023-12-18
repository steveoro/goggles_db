# frozen_string_literal: true

FactoryBot.define do
  factory :relay_lap, class: 'GogglesDb::RelayLap' do
    before_create_validate_instance

    sequence(:length_in_meters) { |n| (n + 1) * 50 }

    meeting_relay_swimmer { GogglesDb::MeetingRelaySwimmer.last(200).sample }
    meeting_relay_result  { meeting_relay_swimmer.meeting_relay_result }
    swimmer               { meeting_relay_swimmer.swimmer }
    team                  { meeting_relay_result.team }

    minutes         { 0 }
    seconds         { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths      { ((rand * 99) % 99).to_i }  # Forced not to use 99

    minutes_from_start    { 1 }
    seconds_from_start    { seconds }
    hundredths_from_start { hundredths }

    position      { (1..10).to_a.sample }
    reaction_time { rand.round(2) }
    stroke_cycles { (rand * 30).to_i }
    #-- -----------------------------------------------------------------------
    #++
  end
end
