FactoryBot.define do
  factory :season, class: 'GogglesDb::Season' do
    edition { ((rand * 1000) % 1000).to_i } # mediumint(9), using a sequence yields validation errors

    sequence(:description) { |n| "Fake Season #{n}/#{edition}" }
    season_type            { GogglesDb::SeasonType.only_masters.sample }
    edition_type           { GogglesDb::EditionType.send(%w[ordinal roman none yearly seasonal].sample) }
    timing_type            { GogglesDb::TimingType.send(%w[manual semiauto automatic].sample) }

    begin_date             { Time.zone.today - (Time.zone.today.month - 1).months + 9.months }
    end_date               { begin_date + 9.months }
    header_year            { "#{begin_date.year}/#{end_date.year}" }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
