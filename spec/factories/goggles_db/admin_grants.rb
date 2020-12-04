FactoryBot.define do
  factory :admin_grant, class: 'GogglesDb::AdminGrant' do
    user
    entity { nil }
  end
end
