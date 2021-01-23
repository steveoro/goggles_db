# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Lap, type: :model do
    shared_examples_for 'a valid Lap instance' do
      it 'is valid' do
        expect(subject).to be_a(Lap).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_program swimmer team meeting event_type pool_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[length_in_meters minutes seconds hundreds]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[reaction_time stroke_cycles breath_cycles position
           minutes_from_start seconds_from_start hundreds_from_start native_from_start
           underwater_kicks underwater_seconds underwater_hundreds
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
    describe 'self.by_distance' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', Lap, 'distance', 'length_in_meters')
    end

    # Filtering scopes:
    describe 'self.with_time' do
      it_behaves_like('filtering scope with_time', Lap)
    end
    describe 'self.with_no_time' do
      it_behaves_like('filtering scope with_no_time', Lap)
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:fixture_row) { FactoryBot.create(:lap) }

    describe 'regarding the timing fields,' do
      # subject = fixture_row (can even be just built, not created)
      it_behaves_like 'TimingManageable'
    end

    describe '#minimal_attributes' do
      subject { fixture_row.minimal_attributes }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[gender_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
      it "contains the 'synthetized' swimmer details" do
        expect(subject['swimmer']).to be_an(Hash).and be_present
        expect(subject['swimmer']).to eq(fixture_row.swimmer_attributes)
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:lap) }

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
