FactoryBot.define do
  factory :category_type, class: 'GogglesDb::CategoryType' do
    season
    age_begin         { (25..100).step(5).to_a.sample }
    age_end           { age_begin + 4 }
    code              { "M#{age_begin}" }
    description       { "MASTER #{age_begin}" }
    short_name        { code }
    # The following is just an internal code and has nothing to do with season.federation_type.code:
    # TODO: rename this field as something like "federation_internal_id" (text)
    federation_code   { (rand * 100).to_i.to_s }
    is_a_relay        { false }
    is_out_of_race    { false }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
