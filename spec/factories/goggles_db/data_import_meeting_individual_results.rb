FactoryBot.define do
  factory :data_import_meeting_individual_result, class: 'GogglesDb::DataImportMeetingIndividualResult' do
    before_create_validate_instance

    sequence(:import_key) do |n|
      program_key = "#{n}-100SL-M45-M"
      swimmer_key = "SWIMMER#{n}|1978|TEAM#{n}"
      "#{program_key}/#{swimmer_key}"
    end

    # String key references (for unmatched entities)
    sequence(:swimmer_key) { |n| "SWIMMER#{n}|1978|TEAM#{n}" }
    sequence(:team_key) { |n| "TEAM#{n}" }
    sequence(:meeting_program_key) { |n| "#{n}-100SL-M45-M" }

    phase_file_path { '/test/phase5.json' }
    meeting_program_id { (1..1000).to_a.sample }
    swimmer_id { (1..1000).to_a.sample }
    team_id { (1..100).to_a.sample }
    badge_id { (1..1000).to_a.sample }
    rank { (0..25).to_a.sample }

    minutes { 0 }
    seconds { ((rand * 59) % 59).to_i }
    hundredths { ((rand * 99) % 99).to_i }

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

    trait :with_zero_time do
      minutes { 0 }
      seconds { 0 }
      hundredths { 0 }
    end

    #-- Nested factories ------------------------------------------------------
    #++

    factory :data_import_meeting_individual_result_with_laps do
      after(:create) do |created_instance, _evaluator|
        base_key = created_instance.import_key
        [50, 100].each do |length|
          FactoryBot.create(
            :data_import_lap,
            parent_import_key: base_key,
            import_key: "#{base_key}/#{length}",
            length_in_meters: length,
            phase_file_path: created_instance.phase_file_path
          )
        end
      end
    end
  end
end
