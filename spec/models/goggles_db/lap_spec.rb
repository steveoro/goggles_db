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
        %i[length_in_meters minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[reaction_time stroke_cycles breath_cycles position
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

    describe 'self.related_laps' do
      context 'given a Lap associated to a MIR,' do
        let(:existing_row) do
          GogglesDb::Lap.joins(:meeting_program)
                        .includes(:meeting_individual_result)
                        .first(300).sample
        end
        let(:result) { GogglesDb::Lap.related_laps(existing_row) }

        it_behaves_like('filtering scope for the same group of Laps')
      end
    end

    describe 'self.summing_laps' do
      context 'given a Lap associated to a MIR,' do
        let(:existing_row) do
          GogglesDb::Lap.joins(:meeting_program)
                        .includes(:meeting_individual_result)
                        .first(300).sample
        end
        let(:result) { GogglesDb::Lap.summing_laps(existing_row) }

        it_behaves_like('filtering scope for the same group of Laps')

        it 'contains only preceding Laps plus the current one' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(Lap)
          expect(result.map(&:length_in_meters)).to all be <= existing_row.length_in_meters
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:fixture_row) { FactoryBot.create(:lap) }

    describe 'regarding the timing fields,' do
      # subject = fixture_row (can even be just built, not created)
      it_behaves_like 'TimingManageable'
    end

    describe '#timing_from_start' do
      context 'for an instance having the "_from_start" values,' do
        before(:each) { expect(fixture_row.seconds_from_start).to be_positive }
        subject { fixture_row.timing_from_start }

        it 'returns the Timing instance computed using the "_from_start" values' do
          expect(subject).to eq(
            Timing.new(
              hundredths: fixture_row.hundredths_from_start,
              seconds: fixture_row.seconds_from_start,
              minutes: fixture_row.minutes_from_start
            )
          )
        end
      end

      context 'for an instance without the "_from_start" values,' do
        let(:existing_row) do
          Lap.where(hundredths_from_start: 0, seconds_from_start: 0, minutes_from_start: 0)
             .first(100)
             .sample
        end
        before(:each) do
          expect(existing_row).to be_a(Lap).and be_valid
          expect(existing_row.seconds_from_start).to be_zero
        end
        subject { existing_row.timing_from_start }

        it 'computes the correct Timing instance using all involved previous laps' do
          involved_laps = Lap.summing_laps(existing_row)
          expect(subject).to eq(
            Timing.new(
              hundredths: involved_laps.sum(:hundredths),
              seconds: involved_laps.sum(:seconds),
              minutes: involved_laps.sum(:minutes)
            )
          )
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

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
      it 'includes the timing string' do
        expect(subject['timing']).to eq(fixture_row.to_timing.to_s)
      end
      it 'includes the timing string from the start of the race' do
        expect(subject['timing_from_start']).to eq(fixture_row.timing_from_start.to_s)
      end
      it "contains the 'synthetized' swimmer details" do
        expect(subject['swimmer']).to be_an(Hash).and be_present
        expect(subject['swimmer']).to eq(fixture_row.swimmer_attributes)
      end
    end

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
