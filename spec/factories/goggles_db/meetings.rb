# frozen_string_literal: true

FactoryBot.define do
  factory :meeting, class: 'GogglesDb::Meeting' do
    sequence(:code) { |n| "meeting-#{n}" }
    description     { "#{FFaker::Name.suffix} #{FFaker::Address.city} Meeting" }
    edition         { (1..40).to_a.sample }
    season
    header_date     { season.begin_date + (rand * 100).to_i.days }
    header_year     { season.header_year }
    edition_type    { GogglesDb::EditionType.send(%w[ordinal roman none yearly seasonal].sample) }
    timing_type     { GogglesDb::TimingType.send(%w[manual semiauto automatic].sample) }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end

    # factory :meeting_with_sessions do
    #   after(:create) do |created_instance, _evaluator|
    #     # Create 1 or 2 sessions:
    #     create_list(:meeting_session, [1, 2].sample, meeting: created_instance)
    #   end
    # end
  end
end
