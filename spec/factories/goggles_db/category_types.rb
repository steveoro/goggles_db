FactoryBot.define do
  factory :category_type, class: 'GogglesDb::CategoryType' do
    before_create_validate_instance

    season
    age_begin         { (25..100).step(5).to_a.sample }
    age_end           { age_begin + 4 }
    code              { "M#{age_begin}" }
    description       { "MASTER #{age_begin}" }
    short_name        { code }
    # The following is just an internal code and has nothing to do with season.federation_type.code:
    # TODO: rename this field as something like "federation_internal_id" (text)
    federation_code   { (rand * 100).to_i.to_s }
    relay             { false }
    out_of_race       { false }
  end
end
