FactoryBot.define do
  factory :meeting_individual_result, class: 'GogglesDb::MeetingIndividualResult' do
    before_create_validate_instance

    badge                     { FactoryBot.create(:badge) }
    swimmer                   { badge.swimmer }
    team                      { badge.team }
    team_affiliation          { badge.team_affiliation }
    meeting_program           { FactoryBot.create(:meeting_program_individual, gender_type_id: swimmer.gender_type_id) }
    rank                      { (0..25).to_a.sample }
    standard_points           { (rand * 1000).to_i }
    meeting_points { standard_points }
    team_points               { (rand * 9).to_i + 1 }
    goggle_cup_points         { (rand * 1000).to_i }
    reaction_time             { rand.round(2) }
    minutes                   { 0 }
    seconds                   { (rand * 59).to_i }
    hundredths                { (rand * 99).to_i }

    disqualification_code_type { [true, false].sample ? GogglesDb::DisqualificationCodeType.all.sample : nil }
    #-- -----------------------------------------------------------------------
    #++

    factory :meeting_individual_result_with_laps do
      after(:create) do |created_instance, _evaluator|
        create_list(
          :lap, (1..4).to_a.sample,
          meeting_program: created_instance.meeting_program,
          meeting_individual_result: created_instance
        )
      end
    end
  end
end
