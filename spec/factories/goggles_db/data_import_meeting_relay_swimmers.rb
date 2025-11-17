FactoryBot.define do
  factory :data_import_meeting_relay_swimmer, class: 'GogglesDb::DataImportMeetingRelaySwimmer' do
    before_create_validate_instance

    sequence(:relay_order) { |n| ((n % 4) + 1) }

    # Generate parent_import_key
    sequence(:parent_import_key) do |n|
      program_key = "#{n}-4X50SL-M160-M"
      team_key = "TEAM#{n}"
      timing = format('%<min>02d:%<sec>02d.%<hun>02d', min: 1, sec: (30 + n) % 60, hun: n % 100)
      "#{program_key}/#{team_key}-#{timing}"
    end

    # Generate swimmer_key and derive import_key
    sequence(:import_key) do |n|
      s_key = "SWIMMER#{n}|1978|TEAM#{n}"
      "mrs#{relay_order}-#{parent_import_key}-#{s_key}"
    end

    # String key references (for unmatched entities)
    sequence(:swimmer_key) { |n| "SWIMMER#{n}|1978|TEAM#{n}" }
    meeting_relay_result_key { parent_import_key }

    phase_file_path { '/test/phase5.json' }
    meeting_relay_result_id { (1..1000).to_a.sample }
    swimmer_id { (1..1000).to_a.sample }
    badge_id { (1..1000).to_a.sample }

    minutes { 0 }
    seconds { ((rand * 59) % 59).to_i }
    hundredths { ((rand * 99) % 99).to_i }

    #-- Traits ----------------------------------------------------------------
    #++

    trait :first_fraction do
      relay_order { 1 }
    end

    trait :second_fraction do
      relay_order { 2 }
    end

    trait :third_fraction do
      relay_order { 3 }
    end

    trait :fourth_fraction do
      relay_order { 4 }
    end

    #-- Nested factory with association ---------------------------------------
    #++

    factory :data_import_meeting_relay_swimmer_with_parent do
      transient do
        parent_result { nil }
        swimmer_key_suffix { 'SWIMMER-1978-M-TEAM' }
      end

      after(:build) do |swimmer, evaluator|
        if evaluator.parent_result
          swimmer.parent_import_key = evaluator.parent_result.import_key
          swimmer_key = "#{evaluator.swimmer_key_suffix}#{swimmer.relay_order}"
          swimmer.import_key = "mrs#{swimmer.relay_order}-#{evaluator.parent_result.import_key}-#{swimmer_key}"
          swimmer.phase_file_path = evaluator.parent_result.phase_file_path
        end
      end
    end
  end
end
