FactoryBot.define do
  factory :import_queue, class: 'GogglesDb::ImportQueue' do
    before_create_validate_instance

    user
    import_queue        { nil } # Parent
    request_data        { {}.to_json }
    solved_data         { {}.to_json }
    process_runs        { 0 }
    done                { false }
    uid                 { FFaker::Guid.guid }
    bindings_left_count { 0 }
    bindings_left_list  { nil }
    error_messages      { nil }
    #-- -----------------------------------------------------------------------
    #++

    factory :import_queue_existing_swimmer do
      request_data do
        existing_row = GogglesDb::Swimmer.first(100).sample
        request_hash = {
          target_entity: 'Swimmer',
          swimmer: {
            complete_name: existing_row.complete_name,
            year_of_birth: existing_row.year_of_birth
          }
        }
        request_hash.to_json
      end
    end

    factory :import_queue_existing_team do
      request_data do
        existing_row = GogglesDb::Team.first(100).sample
        request_hash = {
          target_entity: 'Team',
          team: {
            name: existing_row.name
          }
        }
        request_hash.to_json
      end
    end
  end
end
