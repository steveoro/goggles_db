# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DataImportRelayLap do
    subject { FactoryBot.build(:data_import_relay_lap) }

    let(:parent_key) { subject.parent_import_key }
    let(:valid_attributes) do
      FactoryBot.attributes_for(:data_import_relay_lap)
    end

    context 'with valid attributes' do
      it 'is valid' do
        expect(subject).to be_valid
      end

      it 'can be saved' do
        expect { subject.save! }.not_to raise_error
      end
    end

    context 'validations' do
      it 'requires import_key' do
        subject.import_key = nil
        expect(subject).not_to be_valid
      end

      it 'requires unique import_key' do
        subject.save!
        duplicate = described_class.new(subject.attributes.except('id', 'created_at', 'updated_at'))
        expect(duplicate).not_to be_valid
      end

      it 'requires parent_import_key' do
        subject.parent_import_key = nil
        expect(subject).not_to be_valid
      end

      it 'requires length_in_meters' do
        subject.length_in_meters = nil
        expect(subject).not_to be_valid
      end

      it 'requires length_in_meters > 0' do
        subject.length_in_meters = 0
        expect(subject).not_to be_valid
      end
    end

    describe '#to_timing' do
      it 'returns a Timing instance' do
        expect(subject.to_timing).to be_a(Timing)
      end

      it 'converts timing correctly' do
        timing = Timing.new(
          hundredths: subject.hundredths,
          seconds: subject.seconds,
          minutes: subject.minutes
        )
        expect(subject.to_timing.to_s).to eq(timing.to_s)
      end
    end

    describe '.build_import_key' do
      it 'combines MRR key and length correctly' do
        mrr_key = '1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67'
        length = 50
        expected = '1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67/50'

        result = described_class.build_import_key(mrr_key, length)
        expect(result).to eq(expected)
      end

      it 'handles different lengths' do
        mrr_key = '1-4X100SL-M160-M/CSI-03:30.00'
        result50 = described_class.build_import_key(mrr_key, 50)
        result100 = described_class.build_import_key(mrr_key, 100)

        expect(result50).to end_with('/50')
        expect(result100).to end_with('/100')
      end
    end

    describe 'associations' do
      describe 'data_import_meeting_relay_result' do
        it 'belongs to data_import_meeting_relay_result' do
          expect(subject).to respond_to(:data_import_meeting_relay_result)
        end

        it 'can access parent via composite key' do
          parent = FactoryBot.create(
            :data_import_meeting_relay_result,
            import_key: parent_key
          )

          subject.save!
          expect(subject.data_import_meeting_relay_result).to eq(parent)
        end

        it 'allows optional parent (orphaned laps)' do
          subject.parent_import_key = 'nonexistent-key'
          subject.save!
          expect(subject.data_import_meeting_relay_result).to be_nil
        end
      end
    end
  end
end
