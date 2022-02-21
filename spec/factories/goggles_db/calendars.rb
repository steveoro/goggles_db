# frozen_string_literal: true

FactoryBot.define do
  factory :calendar, class: 'GogglesDb::Calendar' do
    meeting
    season { meeting.season }
    meeting_code { meeting.code }
    meeting_name { meeting.description }
    scheduled_date { meeting.header_date }
    year { meeting.header_date.year }
    month { I18n.t('date.abbr_month_names').fetch(meeting.header_date.month) }
  end
end
