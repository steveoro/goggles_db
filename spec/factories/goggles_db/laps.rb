# frozen_string_literal: true

FactoryBot.define do
  factory :lap, class: 'GogglesDb::Lap' do
    sequence(:length_in_meters) { |n| (n + 1) * 50 }
    meeting_individual_result   { create(:meeting_individual_result) }

    meeting_program { meeting_individual_result.meeting_program }
    minutes         { 0 }
    seconds         { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths      { ((rand * 99) % 99).to_i }  # Forced not to use 99

    minutes_from_start    { 1 }
    seconds_from_start    { seconds }
    hundredths_from_start { hundredths }

    position      { (1..10).to_a.sample }
    reaction_time { rand.round(2) }
    stroke_cycles { (rand * 30).to_i }
    swimmer       { meeting_individual_result.swimmer }
    team          { meeting_individual_result.team }
  end
end
