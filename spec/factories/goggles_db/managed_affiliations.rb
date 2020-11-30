# frozen_string_literal: true

FactoryBot.define do
  factory :managed_affiliation, class: 'GogglesDb::ManagedAffiliation' do
    team_affiliation
    manager { create(:user) }
  end
end
