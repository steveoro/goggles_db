FactoryBot.define do
  factory :data_import_meeting_relay_result, class: 'GogglesDb::DataImportMeetingRelayResult' do
    before_create_validate_instance

    sequence(:import_key) do |n|
      program_key = "#{n}-4X50SL-M160-M"
      team_key = "TEAM#{n}"
      timing = format('%<min>02d:%<sec>02d.%<hun>02d', min: 1, sec: (30 + n) % 60, hun: n % 100)
      "#{program_key}/#{team_key}-#{timing}"
    end

    phase_file_path { '/test/phase5.json' }
    meeting_program_id { (1..1000).to_a.sample }
    team_id { (1..100).to_a.sample }
    team_affiliation_id { (1..500).to_a.sample }
    rank { (0..25).to_a.sample }

    minutes { 1 }
    seconds { (rand * 59).to_i }
    hundredths { (rand * 99).to_i }

    relay_code { %w[A B C D].sample }
    disqualified { false }

    #-- Traits ----------------------------------------------------------------
    #++

    trait :disqualified do
      disqualified { true }
      disqualification_code_type_id { (1..10).to_a.sample }
    end

    trait :with_rank do
      rank { (1..10).to_a.sample }
    end

    trait :relay_a do
      relay_code { 'A' }
    end

    trait :relay_b do
      relay_code { 'B' }
    end

    #-- Nested factories ------------------------------------------------------
    #++

    factory :data_import_meeting_relay_result_with_laps do
      after(:create) do |created_instance, _evaluator|
        base_key = created_instance.import_key
        [50, 100, 150, 200].each do |length|
          FactoryBot.create(
            :data_import_relay_lap,
            parent_import_key: base_key,
            import_key: "#{base_key}/#{length}",
            length_in_meters: length,
            phase_file_path: created_instance.phase_file_path
          )
        end
      end
    end

    factory :data_import_meeting_relay_result_with_swimmers do
      after(:create) do |created_instance, _evaluator|
        base_key = created_instance.import_key
        (1..4).each do |order|
          swimmer_key = "SWIMMER#{order}-1978-M-TEAM#{created_instance.team_id}"
          FactoryBot.create(
            :data_import_meeting_relay_swimmer,
            parent_import_key: base_key,
            import_key: "mrs#{order}-#{base_key}-#{swimmer_key}",
            relay_order: order,
            phase_file_path: created_instance.phase_file_path
          )
        end
      end
    end

    factory :data_import_meeting_relay_result_complete do
      after(:create) do |created_instance, _evaluator|
        base_key = created_instance.import_key

        # Add laps
        [50, 100, 150, 200].each do |length|
          FactoryBot.create(
            :data_import_relay_lap,
            parent_import_key: base_key,
            import_key: "#{base_key}/#{length}",
            length_in_meters: length,
            phase_file_path: created_instance.phase_file_path
          )
        end

        # Add swimmers
        (1..4).each do |order|
          swimmer_key = "SWIMMER#{order}-1978-M-TEAM#{created_instance.team_id}"
          FactoryBot.create(
            :data_import_meeting_relay_swimmer,
            parent_import_key: base_key,
            import_key: "mrs#{order}-#{base_key}-#{swimmer_key}",
            relay_order: order,
            phase_file_path: created_instance.phase_file_path
          )
        end
      end
    end
  end
end
