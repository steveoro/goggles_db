FactoryBot.define do
  factory :meeting_relay_swimmer, class: 'GogglesDb::MeetingRelaySwimmer' do
    before_create_validate_instance

    meeting_relay_result { create(:meeting_relay_result) }
    stroke_type do
      GogglesDb::EventsByPoolType.eventable.relays
                                 .for_pool_type(meeting_relay_result.pool_type)
                                 .event_length_between(50, 800)
                                 .sample
                                 .stroke_type
    end

    relay_order   { [1, 2, 3].sample }
    reaction_time { ((rand * 59) % 59).to_i }  # Forced not to use 59
    minutes       { 0 }
    seconds       { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths    { ((rand * 99) % 99).to_i }  # Forced not to use 99

    badge   { create(:badge, season: meeting_relay_result.team_affiliation.season, team: meeting_relay_result.team) }
    swimmer { badge.swimmer }
    #-- -----------------------------------------------------------------------
    #++
  end
end
