# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: 'GogglesDb::User' do
    name                      { "#{FFaker::Internet.user_name}-#{(rand * 1000).to_i}" }
    email                     { FFaker::Internet.email }
    description               { "#{FFaker::Name.first_name} #{FFaker::Name.last_name}" }
    password                  { 'password' }
    password_confirmation     { 'password' }
    confirmed_at              { Time.zone.now }
    created_at                { Time.zone.now }
    updated_at                { Time.zone.now }
  end
end
