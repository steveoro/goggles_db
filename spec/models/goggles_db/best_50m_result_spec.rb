# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  # Since Best50mResult is a view model, we don't need FactoryBot or database interactions
  # to test simple instance methods like #timing. We can just instantiate the model.
  RSpec.describe Best50mResult do
    subject { described_class.new } # Default instance for basic checks

    describe '#timing' do
      context 'with minutes, seconds, and hundredths' do
        let(:result) { described_class.new(minutes: 1, seconds: 23, hundredths: 45) }

        it 'returns a formatted string with minutes, seconds, and hundredths' do
          expect(result.timing).to eq("1'23\"45")
        end
      end

      context 'with only seconds and hundredths' do
        let(:result) { described_class.new(minutes: 0, seconds: 58, hundredths: 99) }

        it 'returns a formatted string with 0 minutes' do
          expect(result.timing).to eq("0'58\"99")
        end
      end

      context 'with only hundredths' do
        let(:result) { described_class.new(minutes: 0, seconds: 0, hundredths: 7) }

        it 'returns a formatted string with 0 minutes and 0 seconds (leading zeros)' do
          expect(result.timing).to eq("0'00\"07")
        end
      end

      context 'with zero values' do
        let(:result) { described_class.new(minutes: 0, seconds: 0, hundredths: 0) }

        it 'returns a formatted string representing zero time' do
          expect(result.timing).to eq("0'00\"00")
        end
      end

      context 'with nil values' do
        let(:result) { described_class.new(minutes: nil, seconds: 3, hundredths: nil) }

        it 'treats nil values as 0' do
          expect(result.timing).to eq("0'03\"00")
        end
      end

      context 'with values needing leading zeros' do
        let(:result) { described_class.new(minutes: 2, seconds: 5, hundredths: 8) }

        it 'adds leading zeros to seconds and hundredths' do
          expect(result.timing).to eq("2'05\"08")
        end
      end
    end
  end
end
