FactoryBot.define do
  factory :meeting_relay_result, class: 'GogglesDb::MeetingRelayResult' do
    team             { create(:team) }
    meeting_program  { create(:meeting_program_relay) }
    team_affiliation { create(:team_affiliation, team: team, season: meeting_program.season) }
    rank             { (0..25).to_a.sample }
    play_off         { true }
    out_of_race      { false }
    disqualified     { false }
    standard_points  { 500 + (rand * 500).to_i }
    meeting_points   { standard_points }
    minutes          { ((rand * 3) % 3).to_i }
    seconds          { ((rand * 60) % 60).to_i }
    hundredths       { ((rand * 100) % 100).to_i }

    relay_code    { FFaker::Lorem.paragraph[0..50] } # internal name for this relay
    reaction_time { rand.round(2) }

    entry_minutes      { ((rand * 3) % 3).to_i }
    entry_seconds      { ((rand * 60) % 60).to_i }
    entry_hundredths   { ((rand * 100) % 100).to_i }
    entry_time_type_id { GogglesDb::EntryTimeType::LAST_RACE_ID }

    disqualification_code_type { nil } # (No disqualify)
    #-- -----------------------------------------------------------------------
    #++

    factory :meeting_relay_result_with_swimmers do
      after(:create) do |created_instance|
        create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 1)
        create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 2)
        create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 3)
        create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 4)
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
