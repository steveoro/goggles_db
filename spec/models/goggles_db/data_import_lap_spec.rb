# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DataImportLap do
    subject { described_class.new(valid_attributes) }

    let(:parent_key) { '1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI' }
    let(:valid_attributes) do
      {
        import_key: "#{parent_key}/50",
        parent_import_key: parent_key,
        phase_file_path: '/test/phase5.json',
        meeting_individual_result_id: 12_345,
        length_in_meters: 50,
        minutes: 0,
        seconds: 28,
        hundredths: 12
      }
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
        duplicate = described_class.new(valid_attributes)
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
        expect(subject.to_timing.to_s).to eq("0'28\"12")
      end
    end

    describe '.build_import_key' do
      it 'combines MIR key and length correctly' do
        mir_key = '1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI'
        length = 50
        expected = '1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI/50'

        result = described_class.build_import_key(mir_key, length)
        expect(result).to eq(expected)
      end

      it 'handles different lengths' do
        mir_key = '1-200SL-M45-M/ROSSI-1978-M-CSI'
        result50 = described_class.build_import_key(mir_key, 50)
        result100 = described_class.build_import_key(mir_key, 100)

        expect(result50).to end_with('/50')
        expect(result100).to end_with('/100')
      end
    end
  end
end
