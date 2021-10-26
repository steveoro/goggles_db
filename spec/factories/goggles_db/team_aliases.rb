FactoryBot.define do
  factory :team_alias, class: 'GogglesDb::TeamAlias' do
    before_create_validate_instance

    team
    name { "#{team.name}-#{(rand * 100_000).to_i}" }
  end
end
