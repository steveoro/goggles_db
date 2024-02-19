# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_lap_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe Lap do
    shared_examples_for 'a valid Lap instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_program swimmer team
           parent_meeting meeting
           event_type pool_type]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[length_in_meters minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[reaction_time stroke_cycles breath_cycles position
           parent_result meeting_individual_result
           parent_result_id meeting_individual_result_id
           minutes_from_start seconds_from_start hundredths_from_start
           underwater_kicks underwater_seconds underwater_hundredths
           timing_from_start
           meeting_attributes
           to_timing to_json]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:fixture_row) { FactoryBot.create(:lap) }
    let(:existing_row) do
      described_class.joins(:meeting_program)
                     .includes(:meeting_individual_result)
                     .first(300).sample
    end

    context 'any pre-seeded instance' do
      subject { described_class.first(20).sample }

      it_behaves_like('a valid Lap instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:lap) }

      it_behaves_like('a valid Lap instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    it_behaves_like('AbstractLap sorting scopes', described_class)

    # Filtering scopes:
    it_behaves_like('AbstractLap filtering scopes', described_class)

    # TimingManageable:
    describe 'regarding the timing fields,' do
      # subject = fixture_row (can even be just built, not created)
      it_behaves_like('TimingManageable')
    end

    it_behaves_like('AbstractLap #timing_from_start', described_class)
    it_behaves_like('AbstractLap #minimal_attributes', described_class)
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_hash' do
      subject { FactoryBot.create(:lap) }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[gender_type team meeting_program meeting_individual_result event_type category_type]
      )

      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[meeting swimmer]
      )
    end
  end
end
