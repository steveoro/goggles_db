FactoryBot.define do
  factory :meeting_entry, class: 'GogglesDb::MeetingEntry' do
    sequence(:start_list_number)

    meeting_program  { create(:meeting_program) }
    badge            { create(:badge, season: meeting_program.season) }
    team             { badge.team }
    team_affiliation { badge.team_affiliation }
    swimmer          { badge.swimmer }
    minutes          { 0 }
    seconds          { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths       { ((rand * 99) % 99).to_i }  # Forced not to use 99

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
