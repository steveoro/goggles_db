# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_result_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe IndividualRecord do
    shared_examples_for 'a valid IndividualRecord instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Tests the validity of the default_scope when there's an optional association involved:
      it 'does not raise errors when selecting a random row with a field name' do
        expect { described_class.unscoped.where(meeting_individual_result_id: nil).select(:meeting_individual_result_id).first(20).sample }.not_to raise_error
      end

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer team pool_type event_type category_type gender_type
           season season_type federation_type record_type]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[team_name team_editable_name
           swimmer_first_name swimmer_last_name swimmer_complete_name swimmer_year_of_birth
           length_in_meters]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.last(150).sample }

      it_behaves_like('a valid IndividualRecord instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:individual_record) }

      it_behaves_like('a valid IndividualRecord instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_timing' do
      let(:result) { described_class.by_timing.limit(20) }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'to_timing')
    end

    # Filtering scopes:
    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'pool_type')
    end

    describe 'self.for_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'event_type')
    end

    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'season')
    end

    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'swimmer')
    end
  end
end
