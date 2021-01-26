FactoryBot.define do
  factory :meeting_team_score, class: 'GogglesDb::MeetingTeamScore' do
    team_affiliation
    team             { team_affiliation.team }
    season           { team_affiliation.season }
    meeting          { create(:meeting, season: team_affiliation.season) }
    rank             { (1..25).to_a.sample }

    sum_individual_points { (rand * 1000).to_i }
    sum_relay_points      { (rand * 1000).to_i }
    sum_team_points       { (rand * 1000).to_i }
    meeting_points        { (rand * 1000).to_i }
    meeting_relay_points  { (rand * 1000).to_i }
    meeting_team_points   { (rand * 1000).to_i }
    season_points         { 1 + (rand * 1000).to_i }
    season_relay_points   { 1 + (rand * 1000).to_i }
    season_team_points    { 1 + (rand * 1000).to_i }
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
