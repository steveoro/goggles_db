# frozen_string_literal: true

FactoryBot.define do
  factory :calendar, class: 'GogglesDb::Calendar' do
    before_create_validate_instance

    meeting
    season         { meeting.season }
    meeting_code   { meeting.code }
    meeting_name   { meeting.description }
    meeting_place  { "#{FFaker::Address.street_address} - #{FFaker::Address.city}" }
    scheduled_date { meeting.header_date.day }
    year           { meeting.header_date.year }
    month          { I18n.t('date.abbr_month_names').fetch(meeting.header_date.month) }

    # == Note: this factory will generate a random data file that needs to be purged
    #          manually afterwards with something like: "fixture_row.manifest_file.purge"
    factory :calendar_with_dynamic_manifest_file do
      # Attach a sample text file as instance's #manifest_file:
      after(:create) do |saved_instance|
        text_contents = "TEST Manifest for '#{saved_instance.meeting_name}'\r\nImagine a list of events here...\r\n"
        file_path = Rails.root.join('tmp', 'storage', "test-manifest-#{saved_instance.id}.txt")
        File.write(file_path, text_contents)

        saved_instance.manifest_file.attach(
          io: File.open(file_path),
          filename: File.basename(file_path)
        )
      end
    end

    # == Note: DO NOT PURGE the static fixture file used here
    factory :calendar_with_static_manifest_file do
      # Attach a sample text file as instance's #manifest_file:
      after(:create) do |saved_instance|
        file_path = GogglesDb::Engine.root.join('spec', 'fixtures', 'test-manifest.txt')
        saved_instance.manifest_file.attach(
          io: File.open(file_path),
          filename: File.basename(file_path)
        )
      end
    end

    factory :calendar_with_blank_meeting do
      meeting_id     { nil }
      season         { FactoryBot.build(:meeting).season }
      meeting_code   { FactoryBot.build(:meeting).code }
      meeting_name   { FactoryBot.build(:meeting).description }
      scheduled_date { FactoryBot.build(:meeting).header_date.day }
      year           { FactoryBot.build(:meeting).header_date.year }
      month          { I18n.t('date.abbr_month_names').fetch(meeting.header_date.month) }
    end
  end
end
