# frozen_string_literal: true

FactoryBot.define do
  factory :city, class: 'GogglesDb::City' do
    name          { FFaker::Address.city }
    country       { FFaker::Address.country }
    country_code  { FFaker::Address.country_code }

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
