# frozen_string_literal: true

FactoryBot.define do
  factory :meeting, class: 'GogglesDb::Meeting' do
    before_create_validate_instance

    sequence(:code) { |n| "meeting-#{n}" }
    description     { "#{FFaker::Name.suffix} #{FFaker::Address.city} Meeting" }
    edition         { (1..40).to_a.sample }
    season          { FactoryBot.create(:season) }
    header_date     { season.begin_date + (rand * 100).to_i.days }
    header_year     { season.header_year }
    edition_type    { GogglesDb::EditionType.send(%w[ordinal roman none yearly seasonal].sample) }
    timing_type     { GogglesDb::TimingType.send(%w[manual semiauto automatic].sample) }
  end
end
