# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DataImportMeetingIndividualResult do
    subject { FactoryBot.build(:data_import_meeting_individual_result) }

    let(:valid_attributes) do
      FactoryBot.attributes_for(:data_import_meeting_individual_result)
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
        expect(subject.errors[:import_key]).to be_present
      end

      it 'requires unique import_key' do
        subject.save!
        duplicate = described_class.new(subject.attributes.except('id', 'created_at', 'updated_at'))
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:import_key]).to include('has already been taken')
      end

      it 'requires import_key length <= 500' do
        subject.import_key = 'x' * 501
        expect(subject).not_to be_valid
      end

      it 'requires rank' do
        subject.rank = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:rank]).to be_present
      end

      it 'requires rank >= 0' do
        subject.rank = -1
        expect(subject).not_to be_valid
      end
    end

    describe '#to_timing' do
      it 'returns a Timing instance' do
        expect(subject.to_timing).to be_a(Timing)
      end

      it 'converts minutes, seconds, hundredths correctly' do
        subject.minutes = 1
        subject.seconds = 30
        subject.hundredths = 25
        expect(subject.to_timing.to_s).to eq("1'30\"25")
      end

      it 'handles zero values' do
        subject.minutes = 0
        subject.seconds = 0
        subject.hundredths = 0
        expect(subject.to_timing.to_s).to eq("0'00\"00")
      end
    end

    describe '#minimal_attributes' do
      before { subject.save! }

      it 'includes timing string' do
        attrs = subject.minimal_attributes
        expect(attrs).to have_key('timing')
        expect(attrs['timing']).to eq(subject.to_timing.to_s)
      end

      it 'includes standard attributes' do
        attrs = subject.minimal_attributes
        expect(attrs).to have_key('id')
        expect(attrs).to have_key('import_key')
        expect(attrs).to have_key('rank')
      end
    end

    describe '.build_import_key' do
      it 'combines program_key and swimmer_key correctly' do
        program_key = '1-100SL-M45-M'
        swimmer_key = 'ROSSI-1978-M-CSI OBER FERRARI'
        expected = '1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI'

        result = described_class.build_import_key(program_key, swimmer_key)
        expect(result).to eq(expected)
      end

      it 'handles complex keys with special characters' do
        program_key = '2-200MI-F30-F'
        swimmer_key = "BIANCHI-D'ANGELO-1985-F-NUOTO CLUB FIRENZE"
        expected = "2-200MI-F30-F/BIANCHI-D'ANGELO-1985-F-NUOTO CLUB FIRENZE"

        result = described_class.build_import_key(program_key, swimmer_key)
        expect(result).to eq(expected)
      end
    end

    describe 'timestamps' do
      it 'sets created_at on save' do
        subject.save!
        expect(subject.created_at).to be_present
      end

      it 'sets updated_at on save' do
        subject.save!
        expect(subject.updated_at).to be_present
      end
    end

    describe 'indexes' do
      it 'has unique index on import_key' do
        subject.save!
        duplicate = described_class.new(subject.attributes.except('id', 'created_at', 'updated_at'))
        expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    describe 'associations' do
      describe 'data_import_laps' do
        it 'has many data_import_laps' do
          expect(subject).to respond_to(:data_import_laps)
        end

        it 'uses composite key relationship' do
          subject.save!

          lap1 = FactoryBot.create(
            :data_import_lap,
            parent_import_key: subject.import_key,
            import_key: "#{subject.import_key}/50",
            length_in_meters: 50,
            phase_file_path: subject.phase_file_path
          )

          lap2 = FactoryBot.create(
            :data_import_lap,
            parent_import_key: subject.import_key,
            import_key: "#{subject.import_key}/100",
            length_in_meters: 100,
            phase_file_path: subject.phase_file_path
          )

          expect(subject.data_import_laps).to contain_exactly(lap1, lap2)
        end

        it 'deletes laps when parent is destroyed' do
          subject.save!

          lap = FactoryBot.create(
            :data_import_lap,
            parent_import_key: subject.import_key,
            import_key: "#{subject.import_key}/50",
            length_in_meters: 50,
            phase_file_path: subject.phase_file_path
          )

          expect { subject.destroy }.to change(DataImportLap, :count).by(-1)
          expect(DataImportLap.find_by(id: lap.id)).to be_nil
        end

        it 'returns empty array when no laps exist' do
          subject.save!
          expect(subject.data_import_laps).to eq([])
        end
      end
    end
  end
end
