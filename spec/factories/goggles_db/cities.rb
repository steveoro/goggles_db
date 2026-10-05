FactoryBot.define do
  factory :city, class: 'GogglesDb::City' do
    before_create_validate_instance

    # NOTE: a random real city name can resolve to an actual ISO city through
    # CmdFindIsoCity (e.g. "Walkerburgh" => "Walkerburn"), which would make
    # minimal_attributes report the ISO name/coords instead of these columns,
    # breaking the shared-interface spec nondeterministically. A clearly fake
    # name never resolves, so iso_* fall back to the raw column values.
    name          { "Fakecity#{rand(100_000)}" }
    country       { FFaker::Address.country }
    country_code  { FFaker::Address.country_code }
  end
end
