# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'
require 'support/shared_abstract_lap_examples'

module GogglesDb
  RSpec.describe Lap, type: :model do
    shared_examples_for 'a valid Lap instance' do
      it 'is valid' do
        expect(subject).to be_a(Lap).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_program swimmer team
           parent_meeting meeting
           event_type pool_type]
      )

      # Presence of fields & requiredness:
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
    end

    context 'any pre-seeded instance' do
      subject { Lap.all.limit(20).sample }
      it_behaves_like('a valid Lap instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:lap) }
      it_behaves_like('a valid Lap instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    it_behaves_like('AbstractLap sorting scopes', Lap)

    # Filtering scopes:
    let(:existing_row) do
      Lap.joins(:meeting_program)
         .includes(:meeting_individual_result)
         .first(300).sample
    end
    it_behaves_like('AbstractLap filtering scopes', Lap)
    #-- ------------------------------------------------------------------------
    #++

    # TimingManageable:
    let(:fixture_row) { FactoryBot.create(:lap) }

    describe 'regarding the timing fields,' do
      # subject = fixture_row (can even be just built, not created)
      it_behaves_like('TimingManageable')
    end

    it_behaves_like('AbstractLap #timing_from_start', Lap)
    it_behaves_like('AbstractLap #minimal_attributes', Lap)
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      subject { FactoryBot.create(:lap) }

      let(:result) { JSON.parse(subject.to_json) }
      it 'includes the timing string' do
        expect(result['timing']).to eq(subject.to_timing.to_s)
      end
      it 'includes the timing string from the start of the race' do
        expect(result['timing_from_start']).to eq(subject.timing_from_start.to_s)
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_program team meeting_individual_result event_type pool_type]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting swimmer]
      )
    end
  end
end
