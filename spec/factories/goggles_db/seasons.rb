FactoryBot.define do
  factory :season, class: 'GogglesDb::Season' do
    before_create_validate_instance

    edition { ((rand * 1000) % 1000).to_i } # mediumint(9), using a sequence yields validation errors
    sequence(:description) { |n| "Fake Season #{n}/#{edition}" }

    # Let's use educated guesses here with IDs that are always supposed to be there,
    # without invoking the DB in this context to speed up the tests:
    season_type_id  { (1..8).to_a.sample }
    edition_type_id { (1..5).to_a.sample }
    timing_type_id  { (1..3).to_a.sample }
    begin_date      { Time.zone.today - 3.months } # Make the default generated season as already started...
    end_date        { begin_date + 9.months }      # ...And "ongoing"
    header_year     { "#{begin_date.year}/#{end_date.year}" }
  end
end
