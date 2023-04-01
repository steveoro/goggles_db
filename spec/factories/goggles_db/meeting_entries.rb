FactoryBot.define do
  factory :meeting_entry, class: 'GogglesDb::MeetingEntry' do
    before_create_validate_instance

    sequence(:start_list_number)

    meeting_program  { FactoryBot.create(:meeting_program) }
    badge            { FactoryBot.create(:badge, season: meeting_program.season) }
    team             { badge.team }
    team_affiliation { badge.team_affiliation }
    swimmer          { badge.swimmer }
    minutes          { 0 }
    seconds          { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths       { ((rand * 99) % 99).to_i }  # Forced not to use 99
    #-- -----------------------------------------------------------------------
    #++
  end
end
