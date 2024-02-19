FactoryBot.define do
  factory :meeting_relay_result, class: 'GogglesDb::MeetingRelayResult' do
    before_create_validate_instance

    team             { FactoryBot.create(:team) }
    meeting_program  { FactoryBot.create(:meeting_program_relay) }
    team_affiliation { FactoryBot.create(:team_affiliation, team:, season: meeting_program.season) }
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
        FactoryBot.create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 1)
        FactoryBot.create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 2)
        FactoryBot.create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 3)
        FactoryBot.create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: 4)
      end
    end

    # Includes sublap creation (3x RelayLap + 1 MRS)
    factory :meeting_relay_result_4x200 do
      meeting_program do
        mev = FactoryBot.create(
          :meeting_event_relay,
          event_type: GogglesDb::EventType.where(code: %w[S4X200SL M4X200SL]).sample
        )
        FactoryBot.create(:meeting_program_relay, meeting_event: mev)
      end

      after(:create) do |created_instance|
        4.times do |swimmer_idx|
          mrs = FactoryBot.create(:meeting_relay_swimmer, meeting_relay_result: created_instance, relay_order: swimmer_idx + 1)
          (1..3).each do |sublap_idx|
            FactoryBot.create(
              :relay_lap,
              meeting_relay_swimmer: mrs,
              meeting_relay_result: created_instance,
              length_in_meters: (sublap_idx * 50) + (swimmer_idx * 200)
            )
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
