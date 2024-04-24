FactoryBot.define do
  factory :individual_record, class: 'GogglesDb::IndividualRecord' do
    before_create_validate_instance

    meeting_individual_result { GogglesDb::MeetingIndividualResult.last(150).sample }

    swimmer          { meeting_individual_result.swimmer }
    team             { meeting_individual_result.team }

    pool_type        { meeting_individual_result.pool_type }
    event_type       { meeting_individual_result.event_type }
    category_type    { meeting_individual_result.category_type }
    gender_type      { meeting_individual_result.gender_type }
    season           { meeting_individual_result.season }
    federation_type  { meeting_individual_result.federation_type }
    record_type      { GogglesDb::RecordType.first(3).sample }

    minutes         { 0 }
    seconds         { ((rand * 59) % 59).to_i }  # Forced not to use 59
    hundredths      { ((rand * 99) % 99).to_i }  # Forced not to use 99
  end
end
