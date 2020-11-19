# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_session, class: 'GogglesDb::MeetingSession' do
    sequence(:session_order) { |n| n }
    meeting
    swimming_pool # this will yield only "eventable" pools

    description    { 'FINALS' }
    day_part_type  { GogglesDb::DayPartType.all.sample }
    scheduled_date { Time.zone.today }
    warm_up_time   { Time.zone.now }
    begin_time     { Time.zone.now }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
