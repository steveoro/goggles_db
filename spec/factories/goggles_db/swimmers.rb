FactoryBot.define do
  trait :common_swimmer_fields do
    first_name                { FFaker::Name.first_name }
    last_name                 { FFaker::Name.last_name }
    gender_type               { GogglesDb::GenderType.send(%w[male female].sample) }
    year_of_birth             { 18.years.ago.year - ((rand * 100) % 60).to_i }
    complete_name             { "#{last_name} #{first_name}" }
    user
  end
  #-- -------------------------------------------------------------------------
  #++

  factory :swimmer, class: 'GogglesDb::Swimmer' do
    common_swimmer_fields
    e_mail                    { FFaker::Internet.email }
    nickname                  { FFaker::Internet.user_name }
    associated_user_id        { nil }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
