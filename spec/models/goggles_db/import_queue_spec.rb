# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_active_storage_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe ImportQueue do
    shared_examples_for 'a valid ImportQueue instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[
          data_file batch_sql data_file_contents
          done
          import_queue parent
          import_queues sibling_rows
          req solved target_entity root_key result_parent_key
          req_swimmer_name req_event_type
          req_timing req_delta_timing req_length_in_meters
        ]
      )

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[process_runs request_data solved_data]
      )

      it_behaves_like('active storage field with local file', :data_file)
      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Make sure the minimum test domain is existing before each test:
    before { expect(minimum_domain.count).to be_positive }

    # After each test, make sure the attachments are removed:
    after { described_class.with_batch_sql.each { |row| row.data_file.purge } }

    let(:minimum_domain) do
      Prosopite.pause
      FactoryBot.create_list(:import_queue_with_static_data_file, 3)
      FactoryBot.create_list(:import_queue_existing_swimmer, 3, uid: 'FAKE-1')
      FactoryBot.create_list(:import_queue_existing_team, 3, process_runs: 1)
      FactoryBot.create_list(:import_queue_existing_team, 2, process_runs: 1, done: true)
      Prosopite.resume
      described_class.all
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:import_queue) }

      it_behaves_like('a valid ImportQueue instance')
    end

    # Filtering scopes:
    describe 'self.deletable' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'deletable', 'done', true
      )
    end

    describe 'self.with_batch_sql' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'with_batch_sql', 'batch_sql', true
      )
    end

    describe 'self.without_batch_sql' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'without_batch_sql', 'batch_sql', false
      )
    end

    describe 'self.for_user' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'user')
    end

    describe 'self.for_uid' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_uid', 'uid', 'FAKE-1')
    end

    describe '#sibling_rows' do
      context 'when deleting a parent row' do
        let(:parent_row) { FactoryBot.create(:import_queue, uid: 'FAKE-2') }

        before do
          # expect(minimum_domain.count).to be_positive
          expect(parent_row).to be_a(described_class).and be_valid
          # previous_count = parent_row.sibling_rows.count
          Prosopite.pause { FactoryBot.create_list(:import_queue_existing_swimmer, 3, import_queue_id: parent_row.id, uid: 'FAKE-2') }
          parent_row.reload
          expect(parent_row.sibling_rows.count).to eq(3)
        end

        # This is mainly because each IQ row may be solved at a different time,
        # asynchronously from each other, even the dependent ones:
        it 'does not destroy the associated import_queues' do
          expect { parent_row.delete }.to change(described_class, :count).by(-1)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#data_file_contents' do
      subject { fixture_row.data_file_contents }

      let(:fixture_row) { FactoryBot.create(:import_queue_with_static_data_file) }

      it 'returns the string file contents' do
        # (See spec/factories/goggles_db/import_queues.rb:22)
        expect(subject).to start_with('SELECT COUNT(*) FROM ')
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'with a row with valid request_data,' do
      subject do
        FactoryBot.create(
          :import_queue,
          request_data: {
            'target_entity' => 'Lap',
            'lap' => {
              'swimmer' => { 'complete_name' => fixture_swimmer.complete_name },
              'meeting_individual_result' => {
                'event_type_id' => fixture_event_type.id
              },
              'length_in_meters' => meters,
              'minutes' => 0,
              'seconds' => seconds / 2,
              'hundredths' => hundredths / 2,
              'minutes_from_start' => minutes,
              'seconds_from_start' => seconds,
              'hundredths_from_start' => hundredths
            }
          }.to_json
        )
      end

      let(:minutes) { (rand * 5).to_i }
      let(:seconds) { (rand * 59).to_i }
      let(:hundredths) { (rand * 99).to_i }
      let(:meters) { 50 + ((rand * 8).to_i * 50) }
      let(:fixture_swimmer) { GogglesDb::Swimmer.first(150).sample }
      let(:fixture_event_type) { GogglesDb::EventType.all.sample }

      describe '#req' do
        it 'is a non-empty Hash' do
          expect(subject.req).to be_an(Hash).and be_present
        end

        it 'includes the target_entity and the root_key' do
          expect(subject.req.keys).to include('target_entity').and include('lap')
        end
      end

      describe '#solved' do
        it 'is an empty Hash' do
          expect(subject.solved).to be_an(Hash).and be_empty
        end
      end

      describe '#target_entity' do
        it 'is the string value specified in the request_data for target_emtity' do
          expect(subject.target_entity).to eq('Lap')
        end
      end

      describe '#root_key' do
        it 'is the name of the root key' do
          expect(subject.root_key).to eq('lap')
        end
      end

      describe '#result_parent_key' do
        it 'is the name of the first result-like parent for to the current root key' do
          expect(subject.result_parent_key).to eq('meeting_individual_result')
        end
      end

      describe '#req_swimmer_name' do
        it 'is the value set in the request data' do
          expect(subject.req_swimmer_name).to eq(fixture_swimmer.complete_name)
        end
      end

      describe '#req_swimmer_year_of_birth' do
        before do
          expect(fixture_swimmer).to be_a(GogglesDb::Swimmer)
          expect(fixture_event_type).to be_a(GogglesDb::EventType).and be_valid
        end

        context 'with a row that contains birth year data nested under a Swimmer node at depth 1,' do
          let(:fixture_request_data) do
            {
              'target_entity' => 'Whatever',
              'whatever' => {
                'swimmer' => {
                  'complete_name' => fixture_swimmer.complete_name,
                  'year_of_birth' => fixture_swimmer.year_of_birth
                }
              }
            }.to_json
          end

          subject { FactoryBot.create(:import_queue, request_data: fixture_request_data) }

          it 'returns the year of birth of the swimmer' do
            expect(subject.req_swimmer_year_of_birth).to eq(fixture_swimmer.year_of_birth)
          end
        end

        context 'with a row that contains birth year data nested at root level,' do
          let(:fixture_request_data) do
            {
              'target_entity' => 'Swimmer',
              'swimmer' => {
                'complete_name' => fixture_swimmer.complete_name,
                'year_of_birth' => fixture_swimmer.year_of_birth
              }
            }.to_json
          end

          subject { FactoryBot.create(:import_queue, request_data: fixture_request_data) }

          it 'returns the year of birth of the swimmer' do
            expect(subject.req_swimmer_year_of_birth).to eq(fixture_swimmer.year_of_birth)
          end
        end

        context "for a row that doesn't contain any birth year data," do
          let(:fixture_request_data) do
            {
              'target_entity' => 'Swimmer',
              'swimmer' => { 'id' => (rand * 150).to_i } # (Don't care if it's existing or not)
            }.to_json
          end

          subject { FactoryBot.create(:import_queue, request_data: fixture_request_data) }

          it 'is nil' do
            expect(subject.req_swimmer_year_of_birth).to be_nil
          end
        end
      end

      describe '#req_event_type' do
        it 'is an EventType' do
          expect(subject.req_event_type).to be_an(GogglesDb::EventType).and be_valid
        end

        it 'is the corresponding EventType for the ID set in the request data' do
          expect(subject.req_event_type.id).to eq(fixture_event_type.id)
        end
      end

      describe '#req_timing' do
        it 'is a Timing instance' do
          expect(subject.req_timing).to be_a(Timing)
        end

        it 'has the values set in the request data' do
          expect(subject.req_timing).to eq(
            Timing.new(
              minutes:,
              seconds:,
              hundredths:
            )
          )
        end
      end

      describe '#req_delta_timing' do
        it 'is a Timing instance' do
          expect(subject.req_timing).to be_a(Timing)
        end

        it 'has the values set in the request data' do
          expect(subject.req_delta_timing).to eq(
            Timing.new(
              minutes: 0,
              seconds: seconds / 2,
              hundredths: hundredths / 2
            )
          )
        end
      end

      describe '#req_length_in_meters' do
        it 'is the value set in the request data' do
          expect(subject.req_length_in_meters).to eq(meters)
        end
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
