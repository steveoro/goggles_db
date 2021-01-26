FactoryBot.define do
  factory :import_queue, class: 'GogglesDb::ImportQueue' do
    user
    request_data    { {}.to_json }
    solved_data     { {}.to_json }
    processed_depth { 0 }
    requested_depth { 0 }
    solvable_depth  { 0 }
    done            { false }

    factory :import_queue_existing_swimmer do
      request_data do
        existing_row = GogglesDb::Swimmer.first(100).sample
        request_hash = {
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
          team: {
            name: existing_row.name
          }
        }
        request_hash.to_json
      end
    end
    #-- -----------------------------------------------------------------------
    #++

    before(:create) do |built_instance|
      if built_instance.invalid?
        puts "\r\nFactory def. error => " << GogglesDb::ValidationErrorTools.recursive_error_for(built_instance)
        puts built_instance.inspect
      end
    end
  end
end
