# frozen_string_literal: true

FactoryBot.define do
  factory :badge_payment, class: 'GogglesDb::BadgePayment' do
    badge

    payment_date { Time.zone.today }
    amount       { 12.00 }
    manual       { false }

    sequence(:notes) { |n| "Badge payment n.#{n}" }
  end
end
