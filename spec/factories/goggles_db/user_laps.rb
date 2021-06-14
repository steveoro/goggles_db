FactoryBot.define do
  factory :user_lap, class: 'GogglesDb::UserLap' do
    before_create_validate_instance

    user_result

    swimmer { user_result.swimmer }
    length_in_meters { (0..800).step(50).to_a.sample }

    reaction_time { rand.round(2) }
    minutes         { 0 }
    seconds         { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths      { ((rand * 99) % 99).to_i }  # Forced not to use 99
    position        { (1..10).to_a.sample }

    minutes_from_start    { 1 }
    seconds_from_start    { seconds }
    hundredths_from_start { hundredths }
  end
end
