# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdSelectScoreCalculator, type: :command do
    let(:expected_std_timing) do
      GogglesDb::StandardTiming.includes(:category_type)
                               .where('category_types.relay': false)
                               .first(5000).sample
    end

    before { expect(expected_std_timing).to be_a(StandardTiming).and be_valid }

    context 'when using valid parameters,' do
      describe '#call' do
        subject do
          described_class.new(
            pool_type: expected_std_timing.pool_type, event_type: expected_std_timing.event_type,
            season: expected_std_timing.season,
            gender_type: expected_std_timing.gender_type,
            category_type: expected_std_timing.category_type
          ).call
        end

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'is successful' do
          expect(subject).to be_successful
        end

        it 'has a blank #errors list' do
          expect(subject.errors).to be_blank
        end

        it 'returns a type of Calculators::BaseStrategy as #result' do
          expect(subject.result).to be_a(Calculators::BaseStrategy)
          # Additional pedantic check:
          expect(subject.result.standard_timing).to eq(expected_std_timing)
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid constructor parameters,' do
      describe '#call' do
        subject do
          described_class.new(
            pool_type: expected_std_timing.pool_type, event_type: expected_std_timing.event_type,
            season: expected_std_timing.season
          ).call
        end

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a non-empty #errors list displaying an error message about constructor parameters' do
          expect(subject.errors).to be_present
          expect(subject.errors[:msg]).to eq(['Invalid or missing constructor parameters'])
        end

        it 'has a nil #result' do
          expect(subject.result).to be nil
        end
      end
    end
  end
end
