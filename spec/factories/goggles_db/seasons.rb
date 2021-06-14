FactoryBot.define do
  factory :season, class: 'GogglesDb::Season' do
    before_create_validate_instance

    edition { ((rand * 1000) % 1000).to_i } # mediumint(9), using a sequence yields validation errors

    sequence(:description) { |n| "Fake Season #{n}/#{edition}" }
    season_type            { GogglesDb::SeasonType.all_masters.sample }
    edition_type           { GogglesDb::EditionType.send(%w[ordinal roman none yearly seasonal].sample) }
    timing_type            { GogglesDb::TimingType.send(%w[manual semiauto automatic].sample) }
    begin_date             { Time.zone.today - 1.months } # Make the default generated season as already started...
    end_date               { begin_date + 9.months }      # ...And "ongoing"
    header_year            { "#{begin_date.year}/#{end_date.year}" }
  end
end
