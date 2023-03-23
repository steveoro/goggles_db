FactoryBot.define do
  factory :import_queue, class: 'GogglesDb::ImportQueue' do
    before_create_validate_instance

    user
    batch_sql           { false }

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

    # == Note: this factory will generate a random data file that needs to be purged
    #          manually afterwards with something like: "fixture_row.data_file.purge"
    factory :import_queue_with_dynamic_data_file do
      batch_sql { true }

      # Attach a random SQL file as instance's #data_file:
      after(:create) do |saved_instance|
        text_contents = "SELECT COUNT(*) FROM #{%w[users swimmers teams meetings].sample};\r\n"
        file_path = Rails.root.join('tmp', 'storage', "test-data-#{saved_instance.id}.sql")
        File.write(file_path, text_contents)

        saved_instance.data_file.attach(
          io: File.open(file_path),
          filename: File.basename(file_path),
          content_type: 'application/sql'
        )
      end
    end

    # == Note: DO NOT PURGE the static fixture file used here
    factory :import_queue_with_static_data_file do
      # Attach a sample text file as instance's #data_file:
      after(:create) do |saved_instance|
        file_path = GogglesDb::Engine.root.join('spec', 'fixtures', 'test-script.sql')
        saved_instance.data_file.attach(
          io: File.open(file_path),
          filename: File.basename(file_path)
        )
      end
    end

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
