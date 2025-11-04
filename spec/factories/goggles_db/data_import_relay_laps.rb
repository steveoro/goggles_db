FactoryBot.define do
  factory :data_import_relay_lap, class: 'GogglesDb::DataImportRelayLap' do
    before_create_validate_instance

    sequence(:length_in_meters) { |n| ((n % 4) + 1) * 50 }

    # Generate parent_import_key and derive import_key from it
    sequence(:parent_import_key) do |n|
      program_key = "#{n}-4X50SL-M160-M"
      team_key = "TEAM#{n}"
      timing = format('%<min>02d:%<sec>02d.%<hun>02d', min: 1, sec: (30 + n) % 60, hun: n % 100)
      "#{program_key}/#{team_key}-#{timing}"
    end

    import_key { "#{parent_import_key}/#{length_in_meters}" }

    phase_file_path { '/test/phase5.json' }
    meeting_relay_result_id { (1..1000).to_a.sample }

    minutes { 0 }
    seconds { ((rand * 59) % 59).to_i }
    hundredths { ((rand * 99) % 99).to_i }

    minutes_from_start { 0 }
    seconds_from_start { seconds }
    hundredths_from_start { hundredths }

    #-- Traits ----------------------------------------------------------------
    #++

    trait :from_start do
      minutes_from_start { 1 }
      seconds_from_start { (rand * 59).to_i }
      hundredths_from_start { (rand * 99).to_i }
    end

    # rubocop:disable Naming/VariableNumber
    trait :length_50 do
      length_in_meters { 50 }
    end

    trait :length_100 do
      length_in_meters { 100 }
    end

    trait :length_150 do
      length_in_meters { 150 }
    end

    trait :length_200 do
      length_in_meters { 200 }
    end
    # rubocop:enable Naming/VariableNumber

    #-- Nested factory with association ---------------------------------------
    #++

    factory :data_import_relay_lap_with_parent do
      transient do
        parent_result { nil }
      end

      after(:build) do |lap, evaluator|
        if evaluator.parent_result
          lap.parent_import_key = evaluator.parent_result.import_key
          lap.import_key = "#{evaluator.parent_result.import_key}/#{lap.length_in_meters}"
          lap.phase_file_path = evaluator.parent_result.phase_file_path
        end
      end
    end
  end
end
