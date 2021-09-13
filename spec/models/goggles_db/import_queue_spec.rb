# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe ImportQueue, type: :model do
    shared_examples_for 'a valid ImportQueue instance' do
      it 'is valid' do
        expect(subject).to be_an(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[
          done
          import_queue parent
          import_queues sibling_rows
          req solved target_entity root_key result_parent_key
          req_swimmer_name req_event_type req_timing req_length_in_meters
        ]
      )

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[process_runs request_data solved_data]
      )
    end

    before { expect(minimum_domain.count).to be_positive }

    #-- ------------------------------------------------------------------------
    #++

    let(:minimum_domain) do
      FactoryBot.create_list(:import_queue_existing_swimmer, 3, uid: 'FAKE-1')
      FactoryBot.create_list(:import_queue_existing_team, 3, process_runs: 1)
      FactoryBot.create_list(:import_queue_existing_team, 2, process_runs: 1, done: true)
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

    describe 'self.for_user' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'user')
    end

    describe 'self.for_uid' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_uid', 'uid', 'FAKE-1')
    end

    describe '#sibling_rows' do
      context 'when deleting a parent row' do
        let(:parent_row) { described_class.all.sample }

        before do
          expect(minimum_domain.count).to be_positive
          expect(parent_row).to be_a(described_class).and be_valid
          FactoryBot.create_list(:import_queue_existing_swimmer, 3, import_queue_id: parent_row.id, uid: 'FAKE-2')
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

    context 'for a row with valid request_data,' do
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
              'minutes' => minutes,
              'seconds' => seconds,
              'hundredths' => hundredths
            }
          }.to_json
        )
      end

      let(:minutes) { (rand * 5).to_i }
      let(:seconds) { (rand * 59).to_i }
      let(:hundredths) { (rand * 99).to_i }
      let(:meters) { 50 + (rand * 8).to_i * 50 }
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
              minutes: minutes,
              seconds: seconds,
              hundredths: hundredths
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
end
