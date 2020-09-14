# frozen_string_literal: true

FactoryBot.define do
  factory :app_parameter, class: 'GogglesDb::AppParameter' do
    code        { GogglesDb::AppParameter.maximum(:code) + 1 }
    a_string    { '0.001' }
    a_bool      { false }
  end
end
