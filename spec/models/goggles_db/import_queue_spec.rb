# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe ImportQueue, type: :model do
    shared_examples_for 'a valid ImportQueue instance' do
      it 'is valid' do
        expect(subject).to be_an(ImportQueue).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[done]
      )

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[processed_depth requested_depth solvable_depth
           request_data solved_data]
      )
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:import_queue) }
      it_behaves_like('a valid ImportQueue instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:minimum_domain) do
      FactoryBot.create_list(:import_queue_existing_swimmer, 3, processed_depth: 0, requested_depth: 1, uid: 'FAKE-1')
      FactoryBot.create_list(:import_queue_existing_team, 3, processed_depth: 1, requested_depth: 1, solvable_depth: 1)
      ImportQueue.all
    end

    before(:each) { expect(minimum_domain.count).to be_positive }

    # Filtering scopes:
    describe 'self.for_user' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', ImportQueue, 'user')
    end
    describe 'self.for_uid' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', ImportQueue, 'for_uid', 'uid', 'FAKE-1')
    end
    describe 'self.for_processed_depth' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', ImportQueue, 'for_processed_depth', 'processed_depth', [0, 1].sample)
    end
    describe 'self.for_requested_depth' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', ImportQueue, 'for_requested_depth', 'requested_depth', 1)
    end
    describe 'self.for_solvable_depth' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', ImportQueue, 'for_solvable_depth', 'solvable_depth', 1)
    end
  end
end
