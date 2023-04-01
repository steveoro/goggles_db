FactoryBot.define do
  factory :issue, class: 'GogglesDb::Issue' do
    before_create_validate_instance

    user
    code      { GogglesDb::Issue::SUPPORTED_CODES.sample }
    priority  { (0..GogglesDb::Issue::MAX_PRIORITY).to_a.sample }
    status    { (0..GogglesDb::Issue::MAX_PROCESSABLE_STATE).to_a.sample }
    req       { '{}' }
    #-- -----------------------------------------------------------------------
    #++

    # Request upgrade to team manager
    factory :issue_type0 do
      code { '0' }
      req do
        {
          'team_id' => GogglesDb::Team.first(50).pluck(:id).sample,
          'season' => GogglesDb::Season.last(15).pluck(:id).sample(3)
        }.to_json
      end
    end

    # New meeting results url (no workshops for this)
    factory :issue_type1a do
      code { '1a' }
      req do
        {
          'meeting_id' => GogglesDb::Meeting.last(100).pluck(:id).sample,
          'results_url' => FFaker::Internet.http_url
        }.to_json
      end
    end

    # Report missing result
    factory :issue_type1b do
      code { '1b' }
      req do
        {
          'event_type_id' => GogglesDb::EventsByPoolType.eventable.event_length_between(50, 200).sample.event_type_id,
          'swimmer_id' => GogglesDb::Swimmer.last(100).pluck(:id).sample,
          'parent_meeting_id' => GogglesDb::Meeting.last(100).pluck(:id).sample,
          'parent_meeting_class' => 'Meeting',
          'minutes' => [0, 1, 0, 2, 0].sample, 'seconds' => (rand * 59).to_i, 'hundredths' => (rand * 99).to_i
        }.to_json
      end
    end

    # Report result mistake
    factory :issue_type1b1 do
      code { '1b1' }
      req do
        result = [
          GogglesDb::MeetingIndividualResult.last(300).sample,
          GogglesDb::UserResult.last(150).sample
        ].sample
        {
          'result_id' => result.id,
          'result_class' => result.class.name.split('::').last,
          'minutes' => [0, 1, 0, 2, 0].sample, 'seconds' => (rand * 59).to_i, 'hundredths' => (rand * 99).to_i
        }.to_json
      end
    end

    # Report wrong team, swimmer or meeting attribution
    factory :issue_type2b1 do
      code { '2b1' }
      req do
        result = [
          GogglesDb::MeetingIndividualResult.last(300).sample,
          GogglesDb::UserResult.last(150).sample
        ].sample
        flag = %w[wrong_meeting wrong_swimmer wrong_team].sample
        {
          'result_id' => result.id,
          'result_class' => result.class.name.split('::').last,
          flag => '1'
        }.to_json
      end
    end

    # Request change for swimmer association (free select from existing swimmer)
    factory :issue_type3b do
      code { '3b' }
      req  { { 'swimmer_id' => GogglesDb::Swimmer.last(100).pluck(:id).sample }.to_json }
    end

    # Request free edit for associated swimmer
    factory :issue_type3c do
      code { '3c' }
      req do
        {
          'type3c_first_name' => FFaker::Name.first_name,
          'type3c_last_name' => FFaker::Name.last_name,
          'type3c_year_of_birth' => 18.years.ago.year - ((rand * 100) % 70).to_i,
          'type3c_gender_type_id' => GogglesDb::GenderType.send(%w[male female].sample).id
        }.to_json
      end
    end

    # Report generic application error/bug
    factory :issue_type4 do
      code { '4' }
      req do
        {
          'expected' => FFaker::Lorem.sentence,
          'outcome' => FFaker::Lorem.sentence,
          'reproduce' => FFaker::Lorem.sentence
        }.to_json
      end
    end
  end
end
