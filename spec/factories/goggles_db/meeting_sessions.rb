# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_session, class: 'GogglesDb::MeetingSession' do
    before_create_validate_instance

    sequence(:session_order)

    meeting        { create(:meeting) }
    swimming_pool  { create(:swimming_pool) } # this will yield only "eventable" pools
    description    { 'FINALS' }
    day_part_type  { GogglesDb::DayPartType.all.sample }
    scheduled_date { Time.zone.today }
    warm_up_time   { Time.zone.now }
    begin_time     { Time.zone.now }
  end
end
