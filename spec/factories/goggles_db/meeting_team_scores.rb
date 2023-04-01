FactoryBot.define do
  factory :meeting_team_score, class: 'GogglesDb::MeetingTeamScore' do
    before_create_validate_instance

    team_affiliation
    team             { team_affiliation.team }
    season           { team_affiliation.season }
    meeting          { FactoryBot.create(:meeting, season: team_affiliation.season) }
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
  end
end
